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

  describe "#update_nation_builder" do
    let(:person) { create(:person, email: 'user@example.com') }
    let(:location_attributes) do
      {
        address_1:    nil,
        address_2:    nil,
        city:         'Keene',
        zip_code:     nil,
        state_abbrev: nil
      }.stringify_keys
    end
    context "creating new location" do
      it "sends call to update NationBuilder" do
        expect_any_instance_of(Location).to receive(:update_nation_builder).and_call_original
        expect(NbPersonPushAddressJob).to receive(:perform_later).
          with('user@example.com', location_attributes)
        person.create_location(city: 'Keene')
      end
    end
    context "updating existing location" do
      let(:location) { person.create_location(city: 'Berkeley') }
      before { expect(location).to receive(:update_nation_builder).and_call_original }

      it "sends call to update Nation if relevant field changed" do
        expect(NbPersonPushAddressJob).to receive(:perform_later).
          with('user@example.com', location_attributes)
        location.update(city: 'Keene')
      end

      it "doesn't send call to update Nation if no relevant field changed" do
        expect(NbPersonPushAddressJob).not_to receive(:perform_later)
        location.update(city: 'Berkeley')
      end
    end
  end
end
