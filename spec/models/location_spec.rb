# == Schema Information
#
# Table name: locations
#
#  id            :integer          not null, primary key
#  location_type :string
#  address_1     :string
#  address_2     :string
#  city          :string
#  state_id      :integer
#  zip_code      :string
#  person_id     :integer
#  district_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'rails_helper'

describe Location do
  it { should belong_to(:person) }
  it { should validate_presence_of(:state) }
  it { should validate_presence_of(:zip_code) }
  it "doesn't validate presence of zip_code if state is present" do
    expect(Location.new(state: build(:state))).
      not_to validate_presence_of(:zip_code)
  end
  it "doesn't validate presence of state if zip_code is present" do
    expect(Location.new(zip_code: '00001')).not_to validate_presence_of(:state)
  end
  describe "zip_code format" do
    ['00000', '123456789', '11111-0000'].each do |valid_zip|
      it { should allow_value(valid_zip).for(:zip_code) }
    end
    ['bad', '123456', '1234567890', '11111--0000'].each do |bad_zip|
      it { should_not allow_value(bad_zip).for(:zip_code) }
    end
  end

  describe "#state_abbrev=" do
    it "sets state" do
      location = Location.new
      state = create(:state)

      location.state_abbrev = state.abbrev

      expect(location.state).to eq state
    end
  end

  describe "#set_state" do
    it "sets state based on zip" do
      zip = create(:zip_code)
      location = Location.new(zip_code: zip.zip_code)

      location.set_state

      expect(location.state).to eq zip.state
    end
  end

  describe "#set_missing_attributes" do
    it "sets state and district based on zip, if possible" do
      zip = create(:zip_code)
      district = create(:district)
      zip.districts << district
      location = Location.new(zip_code: zip.zip_code)

      location.set_missing_attributes

      expect(location.district).to eq district
      expect(location.state).to eq zip.state
    end

    it "sets district based on address if it can't use zip" do
      location = Location.new(address_1: 'address', zip_code: 'zip')
      district = District.new
      allow(District).to receive(:find_by_address).and_return(district)

      location.set_missing_attributes

      expect(location.district).to eq district
      expect(District).to have_received(:find_by_address).
        with(address: 'address', city: nil, zip_code: 'zip')
    end
  end

  describe "#as_json" do
    it "includes state_abbrev and not state" do
      state = build(:state)
      location = Location.new(address_1: 'address', state: state)

      json = location.as_json

      expect(json).to eq({
        'address_1' => 'address', 'address_2' => nil, 'city' => nil,
        'state_abbrev' => state.abbrev, 'zip_code' => nil
      })
    end
  end
end
