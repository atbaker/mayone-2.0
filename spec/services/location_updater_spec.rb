require 'rails_helper'

describe LocationUpdater do
  describe "#update" do
    bad_addresses = [
      { zip_code: 'bad' },
      { state_abbrev: 'bad' },
      { address_1: 'address', city: 'city' },
    ]

    bad_addresses.each do |bad_address|
      it "doesn't update location for bad address: #{bad_address}" do
        location = build_stubbed_location
        updater = LocationUpdater.new(location, bad_address)

        new_attributes = updater.new_attributes

        expect(new_attributes).to eq({})
      end
    end

    it "ignores zip codes with wrong format" do
      address = { zip_code: 'wrong format', state_abbrev: 'AA' }
      state = stub_state_find('AA')
      location = build_stubbed_location
      updater = LocationUpdater.new(location, address)

      new_attributes = updater.new_attributes

      expect(new_attributes).to eq({ state: state })
    end

    it "finds state based on abbrev" do
      address = { zip_code: '12345', state_abbrev: 'AA' }
      state = stub_state_find('AA')
      location = build_stubbed_location
      updater = LocationUpdater.new(location, address)

      new_attributes = updater.new_attributes

      expect(new_attributes).to eq({ zip_code: '12345', state: state })
    end

    it "finds state based on zip if no state provided" do
      address = { zip_code: '12345' }
      zip_code = stub_zip_code_find('12345')
      location = build_stubbed_location
      updater = LocationUpdater.new(location, address)

      new_attributes = updater.new_attributes

      expect(new_attributes).to eq({ zip_code: '12345', state: zip_code.state })
    end

    it "finds district based on zip if zip has only one district" do
      address = { address_1: 'address', zip_code: '12345' }
      zip_code = stub_zip_code_find('12345', district: 'district')
      location = build_stubbed_location
      updater = LocationUpdater.new(location, address)
      stub_district_find_by_address

      new_attributes = updater.new_attributes

      expect(new_attributes).to include({ district: 'district' })
      expect(District).not_to have_received(:find_by_address)
    end

    it "finds district based on address if address and zip present" do
      address = { address_1: 'address', zip_code: '12345' }
      zip_code = stub_zip_code_find('12345')
      location = build_stubbed_location
      updater = LocationUpdater.new(location, address)
      stub_district_find_by_address('district')

      new_attributes = updater.new_attributes

      expect(new_attributes).to include({ district: 'district' })
      expect(District).to have_received(:find_by_address).
        with(hash_including(address: 'address', zip_code: '12345'))
    end

    context "with no existing location data" do
      it "ignores nils when updating" do
        address = { state_abbrev: 'AL' }
        state = stub_state_find('AL')
        location = build_stubbed_location
        updater = LocationUpdater.new(location, address)

        new_attributes = updater.new_attributes

        expect(new_attributes).to eq({state: state})
      end

      it "doesn't compare locations" do
        address = { state_abbrev: 'AL' }
        state = stub_state_find('AL')
        location = build_stubbed_location
        stub_location_comparer
        updater = LocationUpdater.new(location, address)

        updater.new_attributes

        expect(LocationComparer).not_to have_received(:new)
      end
    end

    context "with existing location data" do
      it "compares locations" do
        address = { city: 'city', state_abbrev: 'AA', zip_code: '12345' }
        state = stub_state_find('AA')
        stub_zip_code_find('12345')
        location = build_stubbed_location(
          city: 'city', state: state, zip_code: '12345'
        )
        stub_location_comparer
        updater = LocationUpdater.new(location, address)

        updater.new_attributes

        expect(LocationComparer).to have_received(:new).
          with(new_city: 'city', new_state: state, new_zip_code: '12345',
               old_city: 'city', old_state: state, old_zip_code: '12345')
      end

      it "preserves old data if locations are similar" do
        address = { zip_code: '12345' }
        stub_zip_code_find('12345')
        location = build_stubbed_location(city: 'city', zip_code: '12345')
        stub_location_comparer(different: false)
        updater = LocationUpdater.new(location, address)

        new_attributes = updater.new_attributes

        expect(new_attributes).not_to include(:city)
      end

      it "overwrites old data if locations are different" do
        address = { zip_code: '12345' }
        stub_zip_code_find('12345')
        location = build_stubbed_location(zip_code: '11111')
        stub_location_comparer(different: true)
        updater = LocationUpdater.new(location, address)

        new_attributes = updater.new_attributes

        expect(new_attributes).to include(*all_location_fields)
      end
    end
  end

  def all_location_fields
    [ :address_1, :city, :state, :zip_code ]
  end

  def stub_district_find_by_address(district = nil)
    allow(District).to receive(:find_by_address).and_return(district)
  end

  def stub_location_comparer(different: false)
    location_comparer = double(:location_comparer)
    allow(location_comparer).to receive(:different?).and_return(different)
    allow(LocationComparer).to receive(:new).and_return(location_comparer)
    location_comparer
  end

  def build_stubbed_location(params = nil)
    location = build_stubbed(:location, params)
    allow(location).to receive(:assign_attributes)
    location
  end

  def stub_state_find(abbrev)
    state = State.new(abbrev: abbrev)
    allow(State).to receive(:find_by).with(abbrev: abbrev).and_return(state)
    state
  end

  def stub_zip_code_find(zip, district: nil)
    zip_code = build_stubbed(:zip_code)
    allow(zip_code).to receive(:single_district).and_return(district)
    allow(ZipCode).to receive(:valid_zip?).with(zip).and_return(true)
    allow(ZipCode).to receive(:find_by).with(zip_code: zip).and_return(zip_code)
    zip_code
  end
end
