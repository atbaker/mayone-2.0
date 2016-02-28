class LocationUpdater
  def initialize(location, address_params)
    @location = location
    @address_params = LocationConstructor.new(address_params).attributes
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
    address_params[:state].present? || address_params[:zip_code].present?
  end

  def relevant_attributes
    if discard_old_values?
      blank_attributes.merge(address_params)
    else
      address_params
    end
  end

  def blank_attributes
    {
      address_1: nil,
      address_2: nil,
      city:      nil,
      zip_code:  nil,
      district:  nil,
      state:     nil,
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
      new_city: address_params[:city],
      new_state: address_params[:state],
      new_zip_code: address_params[:zip_code],
      old_city: location.city,
      old_state: location.state,
      old_zip_code: location.zip_code,
    ).different?
  end
end
