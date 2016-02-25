# == Schema Information
#
# Table name: districts
#
#  id         :integer          not null, primary key
#  district   :string
#  state_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

describe District do
  describe ".find_by_address" do
    let(:state) { FactoryGirl.create(:state, abbrev: 'CA') }
    let!(:district) { FactoryGirl.create(:district, district: '13', state: state) }

    subject(:result) do
      District.find_by_address(address: '123 Main St', zip_code: '94703')
    end

    it "finds district" do
      expect(result).to eq district
    end
  end

  describe "#fetch_rep" do
    let(:state) { FactoryGirl.create(:state, abbrev: 'CA') }
    let(:district) { FactoryGirl.create(:district, district: '13', state: state) }
    subject(:rep) { district.fetch_rep }

    it "associates rep with correct district" do
      expect(rep.district).to eq district
    end
  end
end
