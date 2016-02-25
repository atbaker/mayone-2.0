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

  after_save :update_nation_builder

  def update_location(address_params)
    LocationUpdater.new(self, address_params).assign
    save
  end

  def state_abbrev
    (state || district).try(:abbrev)
  end

  def state_name
    state.try(:name)
  end

  private

  def serializable_hash(options)
    options ||= { methods: [:state_abbrev],
                    only: [:address_1, :address_2, :city, :zip_code] }
    super options
  end

  def update_nation_builder
    if (changed - ["district_id", "created_at", "updated_at"]).any?
      NbPersonPushAddressJob.perform_later(person.email, self.as_json)
    end
  end

end
