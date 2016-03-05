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
require 'validates_email_format_of/rspec_matcher'

describe Person do

  it { should validate_email_format_of(:email).
       with_message('is invalid') }

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

  describe ".create" do
    it "generates uuid" do
      person = Person.create(email: 'user@example.com')
      expect(person.uuid).to_not be_nil
      expect(person.uuid.length).to eq 36
    end
  end

  describe "#last_initial" do
    it "returns first letter of last name" do
      person = Person.new(last_name: "Smith")

      initial = person.last_initial

      expect(initial).to eq "S"
    end

    it "returns empty string if last name is null" do
      person = Person.new

      initial = person.last_initial

      expect(initial).to eq ""
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
