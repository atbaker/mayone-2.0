class LocationComparable < Location

  def merge(other)
    new_attributes = other.address_data
    if similar_to?(other)
      new_attributes.compact!
    end
    assign_attributes(new_attributes)
  end

  def similar_to?(location)
    other_address = location.tap(&:set_state).address_data
    intersection = address_data.compact.keys & other_address.compact.keys
    address_data.slice(*intersection) == other_address.slice(*intersection)
  end

  protected

  def address_data
    attributes.symbolize_keys.slice(*ADDRESS_FIELDS)
  end
end
