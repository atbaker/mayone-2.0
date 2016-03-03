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

class LocationComparable < Location

  def merge(location)
    if similar_to?(location)
      base_values = {}
    else
      base_values = blank_attributes
    end
    assign_attributes(base_values.merge(location.address_data))
  end

  def similar_to?(location)
    new_address = location.tap(&:fill_in_state).address_data
    intersection = address_data.keys & new_address.keys
    address_data.slice(*intersection) == new_address.slice(*intersection)
  end

  protected

  def address_data
    attributes.symbolize_keys.slice(*ADDRESS_FIELDS).compact
  end

  def blank_attributes
    ADDRESS_FIELDS.map{|k| [k, nil]}.to_h
  end
end
