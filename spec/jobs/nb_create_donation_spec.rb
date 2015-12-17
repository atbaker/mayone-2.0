require 'rails_helper'

RSpec.describe NbCreateDonationJob, type: :job do
  describe "#perform" do
    it "pushes person to NationBuilder with correct args" do
      args = { attributes: { email: 'user@example.com', phone: '510-555-9999' } }
      stub_nb_method(:create_or_update_person)

      NbCreateDonationJob.new.perform(400, { email: 'user@example.com',
                                             phone: '510-555-9999' })

      expect(Integration::NationBuilder).to have_received(:create_or_update_person).
        with(args)
    end

    it "creates a donation" do
      stub_nb_method(:create_or_update_person,
                     with_args: { attributes: { email: 'user@example.com' } },
                     returning: { 'id' => 6 })
      stub_nb_method(:create_donation)

      NbCreateDonationJob.new.perform(300, { email: 'user@example.com' })

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
