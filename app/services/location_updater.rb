class LocationUpdater
  def initialize(location, address_params)
    @location = location
    @address_params = address_params
  end

  def new_attributes
    if sufficient_address?
      relevant_attributes
    else
      {}
    end
  end

  private

  attr_reader :location, :address_params

  def sufficient_address?
    find_zip_code || new_state
  end

  def relevant_attributes
    if discard_old_values?
      attributes
    else
      attributes.compact
    end
  end

  def attributes
    {
      address_1: new_address_1,
      address_2: new_address_2,
      city:      new_city,
      zip_code:  new_zip_code,
      district:  find_district,
      state:     find_state,
    }
  end

  def discard_old_values?
    existing_location? && different_address?
  end

  def existing_location?
    [
      location.address_1,
      location.city,
      location.state,
      location.zip_code,
    ].any?
  end

  def different_address?
    LocationComparer.new(
      new_city: new_city,
      new_state: new_state,
      new_zip_code: new_zip_code,
      old_city: location.city,
      old_state: location.state,
      old_zip_code: location.zip_code,
    ).different?
  end

  def find_district
    @_find_district ||= find_district_by_zip || find_district_by_address
  end

  def find_district_by_zip
    find_zip_code.try(:single_district)
  end

  def find_district_by_address
    if new_address_1 && new_zip_code
      search_params = address_params.clone
      search_params[:address] = search_params.delete(:address_1)
      District.find_by_address(search_params)
    end
  end

  def find_state
    new_state || find_zip_code.try(:state)
  end

  def find_zip_code
    @_find_zip_code ||= ZipCode.find_by(zip_code: new_zip_code)
  end

  def new_zip_code
    @_new_zip ||= if ZipCode.valid_zip?(address_params[:zip_code])
                    address_params[:zip_code]
                  end
  end

  def new_state
    @_new_state ||= if address_params[:state_abbrev]
                      State.find_by(abbrev: address_params[:state_abbrev])
                    end
  end

  def new_city
    address_params[:city]
  end

  def new_address_1
    address_params[:address_1]
  end

  def new_address_2
    address_params[:address_2]
  end
end
