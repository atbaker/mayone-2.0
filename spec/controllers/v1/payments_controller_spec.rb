require 'rails_helper'

describe V1::PaymentsController, type: :controller do

  describe "POST create" do
    it "charges stripe" do
      allow(Stripe::Charge).to receive(:create)
      person = spy('person')
      allow(Person).to receive(:create_or_update).and_return(person)

      post :create, amount: 400, source: 'test token', template_id: 'donate',
        person: { email: 'user@example.com' }

      expect(Stripe::Charge).to have_received(:create).
        with(hash_including('amount'=>'400', 'source'=>'test token', 'currency'=>'usd'))
    end

    it "creates/updates person with donation info" do
      allow(Stripe::Charge).to receive(:create)
      person = spy('person')
      allow(Person).to receive(:create_or_update).and_return(person)

      post :create, amount: 400, source: 'test token', template_id: 'donate',
        person: { email: 'user@example.com' }

      expect(Person).to have_received(:create_or_update).
        with(email: 'user@example.com', remote_fields: { donation_amount: '400' })
    end

    it "creates donate action on person" do
      allow(Stripe::Charge).to receive(:create)
      person = spy('person')
      allow(Person).to receive(:create_or_update).and_return(person)

      post :create, amount: 400, source: 'test token', template_id: 'donate',
        person: { email: 'user@example.com' }

      expect(person).to have_received(:create_action).with(template_id: 'donate')
    end
  end

  def json(response)
    JSON.parse(response.body)
  end

end
