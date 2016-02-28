require 'rails_helper'

describe LocationConstructor do
  describe "#update" do
    it "ignores zip codes with wrong format" do
      state = stub_state_find
      address = { zip_code: 'wrong format', state_abbrev: state.abbrev }

      attributes = LocationConstructor.new(address).attributes

      expect(attributes).to eq(state: state)
    end

    it "finds state based on abbrev" do
      state = stub_state_find
      address = { zip_code: '12345', state_abbrev: state.abbrev }

      attributes = LocationConstructor.new(address).attributes

      expect(attributes).to eq(zip_code: '12345', state: state)
    end

    it "finds state based on zip if no state provided" do
      zip = stub_zip_code_find
      address = { zip_code: zip.zip_code }

      attributes = LocationConstructor.new(address).attributes

      expect(attributes).to eq(zip_code: zip.zip_code, state: zip.state)
    end

    it "finds district based on zip if zip has only one district" do
      zip = stub_zip_code_find(single_district: 'district')
      stub_district_find_by_address
      address = { address_1: 'address', zip_code: zip.zip_code }

      attributes = LocationConstructor.new(address).attributes

      expect(attributes).to include(district: 'district')
      expect(District).not_to have_received(:find_by_address)
    end

    it "finds district based on address if address and zip present" do
      zip = stub_zip_code_find
      district = stub_district_find_by_address
      address = { address_1: 'address', zip_code: zip.zip_code }

      attributes = LocationConstructor.new(address).attributes

      expect(attributes).to include(district: district)
      expect(District).to have_received(:find_by_address).
        with(hash_including(address: 'address', zip_code: zip.zip_code))
    end

    it "returns empty hash if state and zip aren't found" do
      address = { state_abbrev: 'AA', zip_code: '00000' }

      attributes = LocationConstructor.new(address).attributes

      expect(attributes).to eq({})
    end
  end

  def stub_district_find_by_address
    district = double('district')
    allow(District).to receive(:find_by_address).and_return(district)
    district
  end

  def stub_state_find
    state = build(:state)
    allow(State).to receive(:find_by).with(abbrev: state.abbrev).
      and_return(state)
    state
  end

  def stub_zip_code_find(single_district: nil)
    zip = build_stubbed(:zip_code)
    allow(zip).to receive(:single_district).and_return(single_district)
    allow(ZipCode).to receive(:find_by).with(zip_code: zip.zip_code).
      and_return(zip)
    zip
  end
end
