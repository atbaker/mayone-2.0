# == Schema Information
#
# Table name: legislators
#
#  id                  :integer          not null, primary key
#  bioguide_id         :string           not null
#  birthday            :date
#  chamber             :string
#  district_id         :integer
#  facebook_id         :string
#  first_name          :string
#  gender              :string
#  in_office           :boolean
#  last_name           :string
#  middle_name         :string
#  name_suffix         :string
#  nickname            :string
#  office              :string
#  party               :string
#  phone               :string
#  senate_class        :integer
#  state_id            :integer
#  state_rank          :string
#  term_end            :date
#  term_start          :date
#  title               :string
#  verified_first_name :string
#  verified_last_name  :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  twitter_id          :string
#

require 'rails_helper'

describe Legislator do
  describe ".create_or_update" do
    context "new record" do
      it "creates record with appropriate values" do
        FactoryGirl.create(:state, abbrev: 'CA')
        hash = { bioguide_id:  'A001',
                 chamber:      'senate',
                 state_abbrev: 'CA',
                 first_name:   'Joe',
                 last_name:    'Smith' }
        rep = Legislator.create_or_update(hash)
        expect(rep.slice(*hash.keys).values).to eq hash.values
      end
    end
    context "existing record" do
      it "updates record with appropriate values" do
        FactoryGirl.create(:senator, bioguide_id: 'A001')
        hash = { bioguide_id:  'A001',
                 first_name:   'Joe',
                 last_name:    'Smith' }
        rep = Legislator.create_or_update(hash)
        expect(rep.slice(*hash.keys).values).to eq hash.values
      end
    end
  end

  describe ".fetch_one" do
    context "by district" do
      let(:state) { FactoryGirl.create(:state, abbrev: 'CA') }
      let(:district) { FactoryGirl.create(:district, district: '13', state: state) }
      subject(:new_rep) { Legislator.fetch_one(district: district) }

      it "returns correct bioguide_id" do
        expect(new_rep.bioguide_id).to eq 'L000551'
      end

      it "returns state == nil" do
        expect(new_rep.state).to be_nil
      end

      it "associates rep with correct district" do
        expect(new_rep.district).to eq district
      end
    end

    context "by state and senate_class" do
      let(:state) { FactoryGirl.create(:state, abbrev: 'CA') }
      subject(:new_senator) { Legislator.fetch_one(state: state, senate_class: 1) }

      it "returns correct bioguide_id" do
        expect(new_senator.bioguide_id).to eq 'F000062'
      end

      it "returns district == nil" do
        expect(new_senator.district).to be_nil
      end

      it "associates senator with correct state" do
        expect(new_senator.state).to eq state
      end
    end

    context "not found" do
      let(:state) { FactoryGirl.create(:state, abbrev: 'not_found') }
      subject(:new_rep) { Legislator.fetch_one(state: state) }

      it "returns nil" do
        expect(new_rep).to be_nil
      end
    end
  end

  describe ".fetch_all" do
    before do
      state = FactoryGirl.create(:state, abbrev: 'CA')
      [11, 25, 31, 33, 35, 45].each do |district|
        FactoryGirl.create(:district, state: state, district: district)
      end
      Legislator.fetch_all
    end

    it "creates correct number of legislators" do
      expect(Legislator.count).to eq 6
    end
  end

  describe "scopes" do
    describe ".default_targeted" do
      subject do
        @rep = FactoryGirl.create(:representative, :targeted, priority: 1)
        @rep2 = FactoryGirl.create(:representative, :targeted)
        @rep3 = FactoryGirl.create(:representative)
        Legislator.default_targeted
      end
      it "only returns default targets" do
        expect(subject.length).to eq(2)
        expect(subject).not_to include(@rep3)
      end
      it "returns targets in priority order" do
        expect(subject[0]).to eq(@rep)
        expect(subject[1]).to eq(@rep2)
      end
    end

    describe ".current_supporters" do
      context "with active cosponsors" do
        it "returns active supporters" do
          bill = FactoryGirl.create(:bill)
          FactoryGirl.create_list(:sponsorship, 3, bill: bill)
          expect(Legislator.current_supporters.count).to eq(3)
        end
      end
      context "with no active cosponsors" do
        it "doesn't find any supporters" do
          expect(Legislator.current_supporters.count).to eq(0)
        end
      end
      context "with cosponsors from old sessions" do
        it "returns only active supporters" do
          bill = FactoryGirl.create(:bill)
          old_bill = FactoryGirl.create(:bill, congressional_session: 113)
          FactoryGirl.create_list(:sponsorship, 1, bill: bill)
          FactoryGirl.create_list(:sponsorship, 2, bill: old_bill)
          expect(Legislator.current_supporters.count).to eq(1)
        end
      end
    end

  end

  describe ".targeted_by_campaign" do
    subject do
      campaign = FactoryGirl.create(:campaign_with_reps, count: 3)
      @alternative_target = FactoryGirl.create(:rep_target)
      Legislator.targeted_by_campaign(campaign.id)
    end
    it "returns the right number of legislators from targeted campaign" do
      expect(subject.length).to eq(3)
    end
    it "doesn't return legislators from other campaigns" do
      expect(subject).not_to include(@alternative_target)
    end
  end

  describe "#targeted?" do
    it "is not targeted by default?" do
      rep = FactoryGirl.create(:representative)
      expect(rep.targeted?).to be_falsy
    end
    context "in a campaign" do
      it "is targeted" do
        rep = FactoryGirl.create(:representative, :targeted, priority: 1)
        expect(rep.targeted?).to be_truthy
      end

      context "a cosponsor" do
        it "is not targeted" do
          rep = FactoryGirl.create(:representative, :targeted, :cosponsor, priority: 1)
          expect(rep.targeted?).to be_falsy
        end
      end
    end
  end

  describe "#title" do
    it "returns Senator for senators" do
      expect(FactoryGirl.build(:senator).title).to eq('Senator')
    end
    it "returns Representative for representative" do
      expect(FactoryGirl.build(:representative).title).to eq('Rep.')
    end
  end

  describe "#display_district" do
    it "returns 'District #' for represenatives not at-large" do
      legislator = FactoryGirl.build(:representative)
      allow(legislator).to receive(:district_code).and_return('1')
      expect(legislator.display_district).to eq('District 1')
    end
    it "returns 'District #' for represenatives not at-large" do
      legislator = FactoryGirl.build(:representative)
      allow(legislator).to receive(:district_code).and_return('0')
      expect(legislator.display_district).to eq('At Large')
    end
    it "returns nil for senators" do
      legislator = FactoryGirl.build(:senator)
      expect(legislator.display_district).to be_nil
    end
  end

  describe "#image_url" do
    before do
      @legislator = FactoryGirl.build(:legislator)
      @bioguide_id = 'b1234'
      allow(@legislator).to receive(:bioguide_id).and_return(@bioguide_id)
    end
    it "calls bioguide_id" do
      @legislator.image_url
      expect(@legislator).to have_received(:bioguide_id)
    end
    it "calls a proper url" do
      aws_url = 'http://some-aws-url.com/'
      ClimateControl.modify TWILIO_AUDIO_AWS_BUCKET_URL: aws_url do
        expect(@legislator.image_url).to eq("#{aws_url}congress-photos/99x120/#{@bioguide_id}.jpg")
      end
    end
  end

  describe "#refetch" do
    let(:state) { FactoryGirl.create(:state, abbrev: 'CA') }
    subject(:senator) { Legislator.fetch_one(state: state, senate_class: 1) }
    before do
      senator.first_name = 'foo'
      senator.refetch
    end

    it "returns correct name" do
      expect(senator.first_name).to eq 'Dianne'
    end
  end

  describe "#serializable_hash" do
    let(:senator) { FactoryGirl.create(:senator) }
    let(:keys) do
      %w[
        id chamber party state_rank name title image_url
        display_district state_abbrev district_code eligible
        state_name with_us last_name bioguide_id phone
      ]
    end

    context "no args" do
      it "returns proper fields" do
        expect(senator.as_json.keys).to match_array keys
      end
    end

    context "with args" do
      subject(:response) { senator.as_json(extras: { extra_key: 'foo' }) }

      it "returns proper fields" do
        expect(response.keys).to match_array(keys + [:extra_key])
      end

      it "returns proper value for extra field" do
        expect(response[:extra_key]).to eq 'foo'
      end
    end
  end
end
