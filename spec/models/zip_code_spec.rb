# == Schema Information
#
# Table name: zip_codes
#
#  id             :integer          not null, primary key
#  zip_code       :string
#  city           :string
#  state_id       :integer
#  district_count :integer
#  on_house_gov   :boolean
#  last_checked   :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'rails_helper'

describe ZipCode do

  describe ".valid_zip_5" do
    it "accepts valid zip codes" do
      good_zips = %w[94703 950601234 05301-1234]
      results = good_zips.select{|zip| ZipCode.valid_zip?(zip) }
      expect(results).to eq %w[94703 950601234 05301-1234]
    end

    it "rejects bad zip codes" do
      bad_zips = %w[1234 123456 12345-124]
      results = bad_zips.select{|zip| ZipCode.valid_zip?(zip) }
      expect(results).to eq []
    end
  end

  describe ".find_by_zip" do
    it "converts input to zip-5 and finds zip_code" do
      allow(ZipCode).to receive(:find_by)

      ZipCode.find_by_zip('111110000')

      expect(ZipCode).to have_received(:find_by).with(zip_code: '11111')
    end
  end
end
