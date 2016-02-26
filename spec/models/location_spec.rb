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

describe Location do
  it "validates required associations" do
    location = Location.new
    location.valid?

    expect(location.errors).to have_key(:person)
  end

  describe "#update_location" do
    it "updates via LocationUpdater" do
      updater = spy(:location_updater)
      allow(LocationUpdater).to receive(:new).and_return(updater)
      location = Location.new

      location.update_location(:address_params)

      expect(LocationUpdater).to have_received(:new).
        with(location, :address_params)
      expect(updater).to have_received(:assign)
    end
  end
end
