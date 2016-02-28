require 'rails_helper'

describe LocationComparer do
  describe "#different?" do
    different_addresses = [
      { old: { zip_code: 'old' }, new: { zip_code: 'new' } },
      { old: { state: 'old' }, new: { state: 'new' } },
      { old: { state: 'same', city: 'old' },
        new: { state: 'same', city: 'new' } },
    ]

    different_addresses.each do |different_address|
      it "returns true for #{different_address}" do
        comparer = LocationComparer.new(different_address)

        result = comparer.different?

        expect(result).to be true
      end
    end

    similar_addresses = [
      { old: { zip_code: 'same' }, new: { zip_code: 'same' } },
      { old: { state: 'same' }, new: { state: 'same' } },
      { old: { state: 'same', city: nil },
        new: { state: 'same', city: 'new' } },
    ]

    similar_addresses.each do |similar_address|
      it "returns false for #{similar_address}" do
        comparer = LocationComparer.new(similar_address)

        result = comparer.different?

        expect(result).to be_falsy
      end
    end
  end

  describe "#new_attributes" do
    it "returns hash with all location keys if locations are different" do
      new = { address_1: 'address', zip_code: 'zip' }

      attributes = LocationComparer.new(old: {}, new: new).new_attributes

      expect(attributes).to include(*Location::PERMITTED_PARAMS)
    end

    it "returns compacted hash if locations are similar" do
      old = { zip_code: 'same' }
      new = { address_1: 'address', zip_code: 'same' }

      attributes = LocationComparer.new(old: old, new: new).new_attributes

      expect(attributes).to eq new
    end
  end
end
