require 'rails_helper'

describe Integration::NationBuilder do

  before(:all) do
    @person_id = 57126
    @event_id = 5
    @rsvp_id = 13
    @donation_id = 69754
  end

  describe "#query_people_by_email" do
    it "formats url for target endpoint" do
      allow(Integration::NationBuilder).to receive(:request_handler).and_call_original

      Integration::NationBuilder.query_people_by_email('dude@gmail.com')

      expect(Integration::NationBuilder).to have_received(:request_handler)
        .with(endpoint_path: Integration::NationBuilder::ENDPOINTS[:people_by_email] % 'dude@gmail.com')
    end
    it "responds with a parsed person_id" do
      response = Integration::NationBuilder.query_people_by_email('dude@gmail.com')
      expect(response).to have_key('id')
      expect(response['id']).to eq(@person_id)
    end
  end

  describe "#create_person_and_rsvp" do
    context "with a person object" do
      it "should call proper methods" do
        person_attributes = {'first_name' => 'Fred', 'email' => 'fred@email.com'}
        allow(Integration::NationBuilder).to receive(:create_or_update_person).and_call_original
        allow(Integration::NationBuilder).to receive(:create_rsvp)

        Integration::NationBuilder.create_person_and_rsvp(event_id: @event_id, person_attributes: person_attributes)

        expect(Integration::NationBuilder).to have_received(:create_or_update_person)
        expect(Integration::NationBuilder).to have_received(:create_rsvp)
      end
    end

    context "with a person_id" do
      it "should call proper methods" do
        person_id = @person_id
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

  describe "#create_or_update_person" do
    it "formats url for target endpoint" do
      body = {person: {'first_name' => 'Fred', 'email' => 'fred@email.com'}}
      allow(Integration::NationBuilder).to receive(:request_handler).and_call_original

      Integration::NationBuilder.create_or_update_person(attributes: {first_name: 'Fred', email: 'fred@email.com'})

      expect(Integration::NationBuilder).to have_received(:request_handler)
        .with(endpoint_path: Integration::NationBuilder::ENDPOINTS[:people], body: body, method: 'put')
    end
    it "responds with a parsed person_id" do
      response = Integration::NationBuilder.create_or_update_person(attributes: {first_name: 'Fred'})
      expect(response).to have_key('id')
      expect(response['id']).to eq(@person_id)
    end
  end

  describe "#create_donation" do
    it "responds with a parsed donation object" do
      response = Integration::NationBuilder.create_donation(amount: 400, person_id: 84961)
      expect(response).to have_key('id')
      expect(response['id']).to eq(@donation_id)
    end
  end

  describe "#create_rsvp" do
    it "formats url for target endpoint" do
      body = {'rsvp': {'person_id': @person_id}}
      allow(Integration::NationBuilder).to receive(:request_handler).and_call_original

      Integration::NationBuilder.create_rsvp(event_id: @event_id, person_id: @person_id)

      expect(Integration::NationBuilder).to have_received(:request_handler)
        .with(endpoint_path: Integration::NationBuilder::ENDPOINTS[:rsvps_by_event] % @event_id,  body: body, method: 'post')
    end
    it "responds with a parsed rsvp_id" do
      response = Integration::NationBuilder.create_rsvp(event_id: @event_id, person_id: @person_id)
      expect(response).to have_key('id')
      expect(response['id']).to eq(@rsvp_id)
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
      it "formats json body for target endpoint" do
        body = { event: event_attributes }
        allow(Integration::NationBuilder).to receive(:request_handler).and_call_original

        Integration::NationBuilder.create_event(attributes: event_attributes)

        expect(Integration::NationBuilder).to have_received(:request_handler)
          .with(endpoint_path: Integration::NationBuilder::ENDPOINTS[:events],
                body: body, method: 'post')
      end
      it "returns event_id" do
        response = Integration::NationBuilder.create_event(attributes: event_attributes)
        expect(response).to eq 13
      end
    end
  end

  describe ".destroy_event" do
    it "returns true" do
      response = Integration::NationBuilder.destroy_event(14)
      expect(response).to eq true
    end
  end

  describe "#list_counts" do
    it "formats url for target endpoint" do
      allow(RestClient).to receive(:get).and_call_original

      Integration::NationBuilder.list_counts

      expect(RestClient).to have_received(:get).with(ENV['NATION_BUILDER_DOMAIN'] + Integration::NationBuilder::ENDPOINTS[:list_count_page])

    end
    it "responds with a parsed list counts" do
      response = Integration::NationBuilder.list_counts
      expect(response).to include(supporter_count: 69087, volunteer_count: 2151)
    end
  end

  describe "#parse_person_attributes" do
    it "should handle allowed params" do
      sample_attributes = {first_name: 'Fred', email: 'dude@gmail.com', bad_param: 'bad'}

      parsed_attributed = Integration::NationBuilder.__send__(:parse_person_attributes, sample_attributes)

      expect(parsed_attributed).not_to have_key(:bad_param)
      expect(parsed_attributed).to have_key(:first_name)
    end
  end
end
