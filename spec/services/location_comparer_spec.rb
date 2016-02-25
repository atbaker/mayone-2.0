require 'rails_helper'

describe LocationComparer do
  describe "#different?" do
    different_addresses = [
      { old_zip_code: 'old', new_zip_code: 'new' },
      { old_state: 'old', new_state: 'new' },
      { old_state: 'same', old_city: 'old',
        new_state: 'same', new_city: 'new' },
    ]

    different_addresses.each do |different_address|
      it "returns true for #{different_address}" do
        comparer = LocationComparer.new(different_address)

        result = comparer.different?

        expect(result).to be true
      end
    end

    similar_addresses = [
      { old_zip_code: 'same', new_zip_code: 'same' },
      { old_state: 'same', new_state: 'same' },
      { old_state: 'same', old_city: nil,
        new_state: 'same', new_city: 'new' },
    ]

    similar_addresses.each do |similar_address|
      it "returns false for #{similar_address}" do
        comparer = LocationComparer.new(similar_address)

        result = comparer.different?

        expect(result).to be_falsy
      end
    end
  end
end
