require 'rails_helper'
include ActiveSupport::Testing::TimeHelpers

describe Integration::NationBuilder do

  before(:each) do
    Integration::NationBuilder.class_variable_set :@@nb_client, nil
  end

  describe ".person_params" do
    it "renames fields and puts location info in nested hash" do
      params = { email: 'email', other: 'other', address_1: 'address',
                 city: 'city', state_abbrev: 'state' }
      expected = {
        email: 'email', other: 'other',
        registered_address: {
          address1: 'address', city: 'city', state: 'state'
        }
      }

      formatted_params = Integration::NationBuilder.person_params(params)

      expect(formatted_params).to eq expected
    end
  end

  describe ".create_person_and_rsvp" do
    context "with a person object" do
      it "should call proper methods" do
        person_attributes = {'first_name' => 'Fred', 'email' => 'fred@email.com'}
        allow(Integration::NationBuilder).to receive(:create_or_update_person).
          and_return({'id' => 4})
        allow(Integration::NationBuilder).to receive(:create_rsvp)

        Integration::NationBuilder.create_person_and_rsvp(event_id: @event_id, person_attributes: person_attributes)

        expect(Integration::NationBuilder).to have_received(:create_or_update_person)
        expect(Integration::NationBuilder).to have_received(:create_rsvp)
      end
    end

    context "with a person_id" do
      it "should call proper methods" do
        person_id = 3
        allow(Integration::NationBuilder).to receive(:create_or_update_person).and_call_original
        allow(Integration::NationBuilder).to receive(:create_rsvp)

        Integration::NationBuilder.create_person_and_rsvp(event_id: @event_id, person_id: person_id)

        expect(Integration::NationBuilder).not_to have_received(:create_or_update_person)
        expect(Integration::NationBuilder).to have_received(:create_rsvp)
      end
    end

    context "without a person_id or person_attributes" do
      it "should raise ArgumentError" do
        expect{ Integration::NationBuilder.create_person_and_rsvp(event_id: @event_id) }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".create_or_update_person" do
    it "responds with person attributes" do
      fake_response = { 'person' => 'person attributes' }
      client = stub_nb_request(response: fake_response)
      attributes = { first_name: 'Fred' }

      response = Integration::NationBuilder.
        create_or_update_person(attributes: attributes)

      expect(client).to have_received(:call).with(:people,
                                                  :push,
                                                  person: attributes)
      expect(response).to eq 'person attributes'
    end
  end

  describe ".create_rsvp" do
    it "responds with rsvp attributes" do
      fake_response = { 'rsvp' => 'rsvp attributes' }
      client = stub_nb_request(response: fake_response)
      event_id = 2
      person_id = 5

      response = Integration::NationBuilder.create_rsvp(event_id: event_id,
                                                        person_id: person_id)

      expect(client).to have_received(:call).with(:events,
                                                  :rsvp_create,
                                                  site_slug: site_slug,
                                                  id: event_id,
                                                  rsvp: { person_id: person_id }
                                                 )
      expect(response).to eq 'rsvp attributes'
    end
  end

  describe "event creation" do
    let(:start) { 1.day.from_now }
    let(:event_attributes) do
      {
        slug: "test_orientation_" + start.to_formatted_s(:number),
        name: "Mayday Call Campaign Orientation",
        start_time: start,
        end_time: start + 1.hour,
        status: "unlisted",
        autoresponse: {
          broadcaster_id: 1,
          subject: "Mayday orientation confirmation"
        }
      }
    end
    describe ".event_params" do
      it "returns properly formatted args" do
        args = { start_time: start, end_time: start + 1.hour }
        expected = { attributes: event_attributes }
        expect(Integration::NationBuilder.event_params(args)).to eq expected
      end
    end

    describe ".create_event" do
      it "returns event id" do
        fake_response = { 'event' => { 'id' => 'event id' } }
        client = stub_nb_request(response: fake_response)

        response = Integration::NationBuilder.
          create_event(attributes: event_attributes)

        expect(client).to have_received(:call).with(:events,
                                                    :create,
                                                    site_slug: site_slug,
                                                    event: event_attributes
                                                   )
        expect(response).to eq 'event id'
      end
    end
  end

  describe ".destroy_event" do
    it "returns true" do
      fake_response = true
      client = stub_nb_request(response: fake_response)
      event_id = 2

      response = Integration::NationBuilder.destroy_event(event_id)

      expect(client).to have_received(:call).with(:events,
                                                  :destroy,
                                                  site_slug: site_slug,
                                                  id: event_id)
      expect(response).to eq true
    end
  end

  describe ".create_donation" do
    it "responds with a parsed donation object" do
      travel_to Time.now do
        fake_response = { 'donation' => 'donation attributes' }
        client = stub_nb_request(response: fake_response)
        amount = 400
        person_id = 5

        response = Integration::NationBuilder.
          create_donation(amount_in_cents: amount, person_id: person_id)

        expect(client).to have_received(:call).with(:donations,
                                                    :create,
                                                    donation: {
                                                      donor_id: person_id,
                                                      amount_in_cents: amount,
                                                      payment_type_name: 'Square',
                                                      succeeded_at: Time.now
                                                    }
                                                   )
        expect(response).to eq 'donation attributes'
      end
    end
  end

  describe ".list_counts" do
    it "formats url for target endpoint" do
      allow(RestClient).to receive(:get).and_call_original

      Integration::NationBuilder.list_counts

      expect(RestClient).to have_received(:get).with(ENV['NATION_BUILDER_DOMAIN'] + Integration::NationBuilder::SUPPORTER_COUNT_ENDPOINT)

    end
    it "responds with a parsed list counts" do
      response = Integration::NationBuilder.list_counts
      expect(response).to include(supporter_count: 69087, volunteer_count: 2151)
    end
  end

  def site_slug
    Integration::NationBuilder::SITE_SLUG
  end

  def stub_nb_request(response:)
    client = double('client')
    allow(client).to receive(:call).and_return(response)
    allow(::NationBuilder::Client).to receive(:new).and_return(client)
    client
  end
end
