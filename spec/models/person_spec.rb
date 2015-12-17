# == Schema Information
#
# Table name: people
#
#  id           :integer          not null, primary key
#  email        :string
#  phone        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  first_name   :string
#  last_name    :string
#  uuid         :string
#  is_volunteer :boolean
#

require 'rails_helper'

describe Person do

  describe "validations" do
    it "validates with an email and no phone" do
      person = Person.new(email: 'user@example.com')
      expect(person.valid?).to be true
    end
    it "validates with a phone and no email" do
      person = Person.new(phone: '555-555-5555')
      expect(person.valid?).to be true
    end
    it "is invalid with no email or phone" do
      person = Person.new
      expect(person.valid?).to be false
    end
  end

  describe "create" do
    it "generates uuid" do
      person = Person.create(email: 'user@example.com')
      expect(person.uuid).to_not be_nil
      expect(person.uuid.length).to eq 36
    end
  end

  describe "#all_called_legislators" do
    it "returns those legislators who are called" do
      call = FactoryGirl.create(:call)
      connections = create_list(:connection, 2, :completed, call: call)
      connection_three = FactoryGirl.create(:connection, :failed, call: call)
      person = call.person

      expected_ids = person.all_called_legislators.map(&:id)
      expect(expected_ids).to eq(connections.map{|c| c.legislator.id})
      expect(expected_ids).not_to include(connection_three.legislator.id)
    end
  end

  describe ".create_or_update" do
    context "new record" do
      it "creates record with appropriate values" do
        create_params = { email: 'user@example.com',
          phone:        '555-555-1111',
          first_name:   'Bob',
          last_name:    'Garfield'}
        expected_params = create_params
        expected_params[:phone] = PhonyRails.normalize_number(create_params[:phone], default_country_code: 'US')

        person = Person.create_or_update(create_params.dup)
        expect(person.slice(*create_params.keys).values).to eq expected_params.values
      end
      it "sets up delayed job in NationBuilder" do
        person = FactoryGirl.build(:person)
        person_params = person.attributes.symbolize_keys
        allow(NbPersonPushJob).to receive(:perform_later).and_call_original

        person = Person.create!(person_params.dup)

        expect(NbPersonPushJob).to have_received(:perform_later).with(person_params.compact)
      end
      it "sends appropriate values to NationBuilder" do
        allow(NbPersonPushJob).to receive(:perform_later).and_call_original
        remote_fields = {tags:['tags'], skills: 'skills'}
        person_params = { email: 'user@example.com',
          phone:        '+15555551111',
          first_name:   'Bob',
          last_name:    'Garfield',
        }
        post_params = person_params.merge(remote_fields: remote_fields)
        expected_params = person_params.merge(remote_fields)

        person = Person.create_or_update(post_params)

        expect(person.attributes.values & person_params.values).to eq(person_params.values)
        expect(person.remote_fields).to eq(remote_fields)
        expect(NbPersonPushJob).to have_received(:perform_later).with(expected_params)
      end
    end
    context "existing record" do
      it "updates record with appropriate values" do
        person = FactoryGirl.create(:person)
        update_params = { email: person.email, phone: '555-555-1111' }

        Person.create_or_update(update_params.dup)
        person.reload

        expect(person.email).to eq update_params[:email]
        expect(person.phone).to eq PhonyRails.normalize_number(update_params[:phone], default_country_code: 'US')
      end
      it "finds existing record even when email case doesn't match" do
        person = FactoryGirl.create(:person)
        random_case_email = person.email.gsub(/./){|c| rand(2)>0 ? c : c.swapcase }
        update_params = { email: random_case_email, phone: '555-555-1111' }

        Person.create_or_update(update_params.dup)
        person.reload

        expect(person.email).to eq update_params[:email].downcase
        expect(person.phone).to eq PhonyRails.normalize_number(update_params[:phone], default_country_code: 'US')
      end
      it "find existing record by phone with string keys" do
        person = FactoryGirl.create(:person)
        find_or_update_params = { phone: person.phone }

        expect{
          @updated_person = Person.create_or_update(find_or_update_params)
        }.not_to change{ Person.count }
        expect(@updated_person.id).to eq(person.id)
      end
      it "find existing record by phone after email search fails" do
        person = FactoryGirl.create(:person, email: nil)
        find_or_update_params = { phone: person.phone, email: 'fake@mail.com' }

        expect{
          @updated_person = Person.create_or_update(find_or_update_params)
        }.not_to change{ Person.count }
        expect(@updated_person.id).to eq(person.id)
      end
      it "finds user based on uuid, if present" do
        person = FactoryGirl.create(:person)
        update_params = { email: 'new_unique_email_address@example.com', uuid: person.uuid }

        Person.create_or_update(update_params.dup)
        person.reload

        expect(person.email).to eq update_params[:email]
      end
    end
  end

  describe "#save_location" do

    it "calls update location if zip present" do
      expect_any_instance_of(Location).to receive(:update_location).
        with(address: '2020 Oregon St', zip: '94703', city: nil) { true }
      Person.create(email: 'user@example.com', address: '2020 Oregon St', zip: '94703')
    end

    it "doesn't update location if zip not present" do
      expect_any_instance_of(Location).not_to receive(:update_location)
      Person.create(email: 'user@example.com', address: '2020 Oregon St')
    end

  end

  describe "#constituent_of?" do
    let(:voter) { FactoryGirl.create(:person, :with_district) }

    it "returns nil if person has no state/district" do
      person = FactoryGirl.create(:person)
      rep = FactoryGirl.create(:representative)
      expect(person.constituent_of? rep).to be_nil
    end

    it "returns true if rep in person's district" do
      rep = FactoryGirl.create(:representative, district: voter.district)
      expect(voter.constituent_of? rep).to be true
    end

    it "returns true if senator in person's state" do
      senator = FactoryGirl.create(:senator, state: voter.state)
      expect(voter.constituent_of? senator).to be true
    end

    it "returns false if rep in other district" do
      rep = FactoryGirl.create(:representative)
      expect(voter.constituent_of? rep).to be false
    end

  end

  describe "targeting" do
    let(:voter)   { FactoryGirl.create(:person, :with_district) }

    describe "#other_targets" do

      it "only returns targeted legislators" do
        targeted_reps = FactoryGirl.create_list(:representative, 2, :targeted)
        result_reps = voter.other_targets(count: 5, excluding: [])
        expect(result_reps).to eq(targeted_reps)
      end

      it "excludes legislators" do
        rep1 = FactoryGirl.create(:representative, :targeted, priority: 1)
        rep2 = FactoryGirl.create(:representative, :targeted, priority: 2)

        expect(voter.other_targets(count: 5, excluding: [rep1])).to eq [rep2]
      end

      it "returns correct number of legislators" do
        FactoryGirl.create(:campaign_with_reps, count: 3, priority: 1)
        expect(voter.other_targets(count: 2, excluding: []).count).to eq 2
      end

    end

    describe "#target_legislators" do

      context "normal" do
        subject(:legislators) { voter.target_legislators }

        it "returns default targets for person with no district/state" do
          person = FactoryGirl.create(:person)
          rep = FactoryGirl.create(:representative, :targeted, priority: 1)
          expect(person.target_legislators).to eq [rep]
        end

        it "returns local target followed by other targets, if targeted" do
          rep = FactoryGirl.create(:representative, :targeted, priority: 1)
          unconvinced_senator = FactoryGirl.create(:senator, :targeted, state: voter.state)
          expect(legislators).to eq [unconvinced_senator, rep]
        end

        it "doesn't return local targets twice" do
          local_rep = FactoryGirl.create(:representative, :targeted, priority: 1,
                                            district: voter.district)
          other_rep = FactoryGirl.create(:representative, :targeted, priority: 1)
          expect(legislators).to eq [local_rep, other_rep]
        end

        it "doesn't include rep with us" do
          rep_with_us = FactoryGirl.create(:representative, :with_us, district: voter.district)
          expect(legislators).not_to include rep_with_us
        end

        it "doesn't include ineligible senators" do
          senator = FactoryGirl.create(:senator, state: voter.state, term_end: 3.years.from_now)
          expect(legislators).not_to include senator
        end

        it "doesn't return untargeted locals" do
          local_rep = FactoryGirl.create(:representative, district: voter.district)
          expect(legislators).not_to include local_rep
        end

        it "doesn't return untargeted locals into the current campaign" do
          local_rep = FactoryGirl.create(:representative, :targeted, district: voter.district)
          campaign = FactoryGirl.create(:campaign_with_reps, count: 3)

          targeted = voter.target_legislators(campaign_id: campaign.id)

          expect(targeted).not_to include local_rep
        end
      end

      context "json" do

        it "works with empty array" do
          person = FactoryGirl.create(:person)
          expect(person.target_legislators(json: true)).to eq []
        end

        it "sets local attribute for all targets" do
          FactoryGirl.create(:senator, :targeted, state: voter.state)
          FactoryGirl.create(:representative, :targeted, priority: 1)
          locals = voter.target_legislators(json: true).map{|leg| leg[:local] }
          expect(locals).to eq [true, false]
        end

      end

      context "with count arg" do

        it "returns appropriate count" do
          FactoryGirl.create(:campaign_with_reps, count: 3, priority: 1)
          expect(voter.target_legislators(count: 2).count).to eq 2
        end

      end
    end
  end

  describe "#update_nation_builder" do
    context "creating new user" do
      it "sends call to update NationBuilder" do
        expect_any_instance_of(Person).to receive(:update_nation_builder).and_call_original
        expect(NbPersonPushJob).to receive(:perform_later).
          with(email: 'user@example.com', phone: PhonyRails.normalize_number('6305551234', default_country_code: 'US') )
        Person.create(email: 'user@example.com', phone:'630-555-1234')
      end
    end
    context "updating existing user" do
      let(:person) { FactoryGirl.create(:person, :with_nb_callback) }
      before { expect(person).to receive(:update_nation_builder).and_call_original }

      it "sends remote_fields to NationBuilder if present" do
        expect(NbPersonPushJob).to receive(:perform_later).
          with(email: person.email, phone: person.phone, tags: ['test'], foo: 'bar')
        person.update(remote_fields: { tags: ['test'], foo: 'bar' })
      end

      it "sends call to update NationBuilder if relevant field changed" do
        expect(NbPersonPushJob).to receive(:perform_later).
          with(email: person.email, phone: person.phone, first_name: 'Bob')
        person.update(first_name: 'Bob')
      end

      it "doesn't send call to update NationBuilder if no relevant field changed" do
        expect(NbPersonPushJob).not_to receive(:perform_later)
        person.update(phone: person.phone)
      end
    end
  end

  describe "call counting" do
    subject do
      connection = FactoryGirl.create(:connection, :failed)
      FactoryGirl.create(:connection, :completed, call: connection.call)
      connection.person
    end
    describe ".set_remote_call_counts!" do
      it "push the correct params to the update job" do
        allow(NbPersonPushJob).to receive(:perform_later)
        expected_arguments = {
          email: subject.email,
          phone: subject.phone,
          representative_call_attempts: 2,
          representative_calls_count: 1
        }

        subject.set_remote_call_counts!
        expect(NbPersonPushJob).to have_received(:perform_later).with(expected_arguments)
      end
    end
    describe "#representative_call_attempts" do
      it "counts all connections" do
        expect(subject.representative_call_attempts).to eq(2)
      end
    end
    describe "#representative_calls_count" do
      it "counts successfuly connections" do
        expect(subject.representative_calls_count).to eq(1)
      end
    end
  end

  describe "#create_action" do
    it "saves a new action with correct associations" do
      person = FactoryGirl.create(:person)
      activity = FactoryGirl.create(:activity)
      action_params = {
        utm_source: 'expected_source',
        utm_medium: 'expected_medium',
        utm_campaign: 'expected_campaign',
        source_url: 'expected_url'
      }

      person.create_action(action_params.merge(template_id: activity.template_id))

      expect(person.actions.first.activity).to eq(activity)
      expect(person.actions.first.attributes).to include(action_params.stringify_keys)
    end

  end
end
