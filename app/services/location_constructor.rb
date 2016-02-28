class LocationConstructor

  def initialize(address)
    @address = address
    validate_and_fill_in_attributes
  end

  def attributes
    fields = Location.attribute_names.map(&:to_sym) + [:district, :state]
    address.compact.slice(*fields)
  end

  private

  attr_reader :address

  def validate_and_fill_in_attributes
    validate_zip
    set_state
    set_district
  end

  def validate_zip
    unless ZipCode.valid_zip?(address[:zip_code])
      address.delete(:zip_code)
    end
  end

  def set_state
    address[:state] = if address[:state_abbrev]
                           State.find_by(abbrev: address[:state_abbrev])
                         else
                           find_zip_code.try(:state)
                         end
  end

  def set_district
    address[:district] = find_district_by_zip || find_district_by_address
  end

  def find_district_by_zip
    find_zip_code.try(:single_district)
  end

  def find_district_by_address
    if address[:address_1] && address[:zip_code]
      search_params = address.
        slice(:city, :state_abbrev, :zip_code).
        merge(address: address[:address_1])
      District.find_by_address(search_params)
    end
  end

  def find_zip_code
    if address[:zip_code]
      @_find_zip_code ||= ZipCode.find_by(zip_code: address[:zip_code])
    end
  end
end
