require 'rails_helper'

RSpec.describe NbPersonPushJob, type: :job do
  describe "#perform" do
    it "calls NationBuilder with correct args" do
      args = { attributes: { email: 'user@example.com', phone: '510-555-9999' } }
      stub_nb_method(:create_or_update_person)

      NbPersonPushJob.new.perform(email: 'user@example.com', phone: '510-555-9999')

      expect(Integration::NationBuilder).to have_received(:create_or_update_person).
        with(args)
    end

    it "creates RSVP when event_id is present" do
      stub_nb_method(:create_or_update_person,
                     with_args: { attributes: { email: 'user@example.com' } },
                     returning: { 'id' => 6 })
      stub_nb_method(:create_rsvp)

      NbPersonPushJob.new.perform(email: 'user@example.com', event_id: 4)

      expect(Integration::NationBuilder).to have_received(:create_rsvp)
        .with(event_id: 4, person_id: 6)
    end

    it "creates a donation when donation_amount is present" do
      stub_nb_method(:create_or_update_person,
                     with_args: { attributes: { email: 'user@example.com' } },
                     returning: { 'id' => 6 })
      stub_nb_method(:create_donation)

      NbPersonPushJob.new.perform(email: 'user@example.com', donation_amount: 300 )

      expect(Integration::NationBuilder).to have_received(:create_donation).
        with(amount: 300, person_id: 6)
    end
  end

  def stub_nb_method(method, with_args: nil, returning: nil)
    allow(Integration::NationBuilder).to receive(method).
      with(with_args || any_args).
      and_return(returning)
  end
end
