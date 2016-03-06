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

class Location < ActiveRecord::Base
  belongs_to :person, required: true
  belongs_to :district
  belongs_to :state

  validates :state, presence: true, unless: :zip_code
  validates :zip_code, presence: true, unless: :state
  validates :zip_code, allow_nil: true,
    format: { with: /\A\d{5}[^\w]?(\d{4})?\z/ }

  ADDRESS_FIELDS = [
    :address_1, :address_2, :city, :state_id, :zip_code, :district_id
  ]
  PERMITTED_PARAMS = ADDRESS_FIELDS + [:state_abbrev]

  def state_abbrev
    (state || district).try(:abbrev)
  end

  def state_abbrev=(abbrev)
    self.state = State.find_by(abbrev: abbrev)
  end

  def fill_in_missing_attributes
    fill_in_state
    fill_in_district
  end

  def fill_in_state
    self.state_id ||= find_zip_code.try(:state_id)
  end

  private

  def fill_in_district
    self.district ||= find_district_by_zip || find_district_by_address
  end

  def find_district_by_zip
    find_zip_code.try(:single_district)
  end

  def find_district_by_address
    if address_1 && zip_code
      search_params = attributes.symbolize_keys.
        slice(:city, :state_abbrev, :zip_code).
        merge(address: address_1)
      District.find_by_address(search_params)
    end
  end

  def find_zip_code
    @_find_zip_code ||= zip_code && ZipCode.find_by_zip(zip_code)
  end

  def serializable_hash(options)
    options ||= { methods: [:state_abbrev],
                    only: [:address_1, :address_2, :city, :zip_code] }
    super options
  end
end
