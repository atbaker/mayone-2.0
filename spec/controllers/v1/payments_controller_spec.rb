require 'rails_helper'

describe V1::PaymentsController, type: :controller do

  describe "POST create" do
    it "creates subscription if recurring == true" do
      person = stub_person_create_or_update
      stub_stripe_customer_create(id: 'customer id',
                                  subscription_id: 'subscription id')

      post :create, amount: 400, source: 'test token', template_id: 'donate',
        recurring: true, person: { email: 'user@example.com' }

      expect(Stripe::Customer).to have_received(:create).
        with(plan: 'one_dollar_monthly',
         email: 'user@example.com',
         quantity: 4,
         'source' => 'test token')
      expect(person).to have_received(:update).with(stripe_id: 'customer id')
      expect(person).to have_received(:create_subscription).
        with(remote_id: 'subscription id')
    end

    it "charges stripe once if recurring is falsy" do
      allow(Stripe::Charge).to receive(:create)
      stub_person_create_or_update

      post :create, amount: 400, source: 'test token', template_id: 'donate',
        person: { email: 'user@example.com' }

      expect(Stripe::Charge).to have_received(:create).
        with(hash_including('amount' => '400', 'source' => 'test token', currency: 'usd'))
    end

    it "creates/updates person with donation info" do
      allow(Stripe::Charge).to receive(:create)
      stub_person_create_or_update

      post :create, amount: 400, source: 'test token', template_id: 'donate',
        person: { email: 'user@example.com' }

      expect(Person).to have_received(:create_or_update).
        with(email: 'user@example.com', remote_fields: { donation_amount: 400 })
    end

    it "creates donate action on person" do
      allow(Stripe::Charge).to receive(:create)
      person = stub_person_create_or_update

      post :create, amount: 400, source: 'test token', template_id: 'donate',
        person: { email: 'user@example.com' }

      expect(person).to have_received(:create_action).
        with(template_id: 'donate', donation_amount_in_cents: 400)
    end
  end

  def json(response)
    JSON.parse(response.body)
  end

  def stub_person_create_or_update
    person = spy('person')
    allow(Person).to receive(:create_or_update).and_return(person)
    person
  end

  def stub_stripe_customer_create(id: '', subscription_id: '')
    customer = spy('customer')
    allow(customer).to receive(:id).and_return(id)
    subscription_data = OpenStruct.new(data: [OpenStruct.new(id: subscription_id)])
    allow(customer).to receive(:subscriptions).and_return(subscription_data)
    allow(Stripe::Customer).to receive(:create).and_return(customer)
  end

end
