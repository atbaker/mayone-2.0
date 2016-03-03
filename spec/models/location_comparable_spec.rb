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

describe LocationComparable do
  describe "#merge" do
    it "assigns attributes" do
      location = LocationComparable.new
      other = LocationComparable.new(address_1: 'foo', zip_code: '00000')

      location.merge(other)

      expect(location.address_1).to eq 'foo'
      expect(location.zip_code).to eq '00000'
    end

    it "clears old values if new address is different" do
      location = LocationComparable.new(address_1: 'address', zip_code: '11111')
      other = LocationComparable.new(city: 'city', zip_code: '00000')

      location.merge(other)

      expect(location.address_1).to be_nil
      expect(location.city).to eq 'city'
      expect(location.zip_code).to eq '00000'
    end

    it "does nothing if new address is blank" do
      location = LocationComparable.new(city: 'city')
      other = LocationComparable.new({})

      location.merge(other)

      expect(location.city).to eq 'city'
    end
  end

  describe "#similar_to?" do
    it "returns true if no new value differs from existing value" do
      location = LocationComparable.new(city: 'city', zip_code: '11111')
      other = LocationComparable.new(zip_code: '11111')

      similar = location.similar_to?(other)

      expect(similar).to be true
    end

    it "doesn't compare fields where either value is null" do
      location = LocationComparable.new(address_1: 'address', zip_code: '11111')
      other = LocationComparable.new(city: 'city', state_abbrev: 'AA')

      similar = location.similar_to?(other)

      expect(similar).to be true
    end

    it "returns false if any new value differs from existing value" do
      location = LocationComparable.new(city: 'city', zip_code: '11111')
      other = LocationComparable.new(city: 'city', zip_code: '22222')

      similar = location.similar_to?(other)

      expect(similar).to be false
    end

    it "tries to guess state of new address if none given" do
      zip = create(:zip_code)
      location = LocationComparable.new(state: build_stubbed(:state))
      other = LocationComparable.new(city: 'city', zip_code: zip.zip_code)

      similar = location.similar_to?(other)

      expect(similar).to be false
    end
  end
end
