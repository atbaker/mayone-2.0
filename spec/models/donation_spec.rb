require 'rails_helper'
require 'validates_email_format_of/rspec_matcher'

describe Donation do

  it { should validate_presence_of(:person) }
  it { should validate_presence_of(:stripe_token) }
  it { should validate_presence_of(:employer) }
  it { should validate_presence_of(:occupation) }
  it { should validate_presence_of(:amount_in_cents) }
  it { should validate_numericality_of(:amount_in_cents) }

  describe "process" do
    it "creates subscription if recurring is true" do
      person = stub_person
      allow(person).to receive(:update)
      allow(person).to receive(:create_subscription)

      stub_stripe_customer_create(id: 'customer id',
                                  subscription_id: 'subscription id')
      donation = Donation.new(amount_in_cents: 400, stripe_token: 'test token',
        recurring: true, person: person, occupation: 'job',
        employer: 'work place')

      donation.process

      expect(Stripe::Customer).to have_received(:create).
        with(plan: 'one_dollar_monthly',
         email: person.email,
         quantity: 4,
         source: 'test token')
      expect(person).to have_received(:update).with(stripe_id: 'customer id')
      expect(person).to have_received(:create_subscription).
        with(remote_id: 'subscription id')
    end

    it "charges stripe once if recurring not provideded" do
      allow(Stripe::Charge).to receive(:create)
      person = stub_person
      donation = Donation.new(amount_in_cents: 400, stripe_token: 'test token',
        person: person, occupation: 'job', employer: 'work place')

      donation.process

      expect(Stripe::Charge).to have_received(:create).
        with(hash_including(amount: 400, source: 'test token', currency: 'usd'))
    end

    it "charges stripe once if recurring is falsy" do
      allow(Stripe::Charge).to receive(:create)
      person = stub_person
      donation = Donation.new(amount_in_cents: 400, stripe_token: 'test token',
        person: person, occupation: 'job', employer: 'work place', recurring: 'false')

      donation.process

      expect(Stripe::Charge).to have_received(:create).
        with(hash_including(amount: 400, source: 'test token', currency: 'usd'))
    end

    it "updates CRM with donation info" do
      allow(Stripe::Charge).to receive(:create)
      person = stub_person
      allow(NbDonationCreateJob).to receive(:perform_later)
      donation = Donation.new(amount_in_cents: 400, stripe_token: 'test token',
        person: person, occupation: 'job', employer: 'work place')

      donation.process

      expect(NbDonationCreateJob).to have_received(:perform_later).
        with(400, { email: person.email, occupation: 'job', employer: 'work place' })
    end

    it "creates donate action on person" do
      allow(Stripe::Charge).to receive(:create)
      person = stub_person
      donation = Donation.new(amount_in_cents: 400, stripe_token: 'test token',
        person: person, occupation: 'job', employer: 'work place')

      donation.process

      expect(person).to have_received(:create_action).
        with(hash_including(template_id: 'donate', donation_amount_in_cents: 400))
    end
  end

  def stub_person
    person = build_stubbed(:person)
    allow(person).to receive(:create_action)
    person
  end

  def stub_stripe_customer_create(id: '', subscription_id: '')
    subscriptions = [OpenStruct.new(id: subscription_id)]
    customer = double('customer', id: id, subscriptions: subscriptions)
    allow(Stripe::Customer).to receive(:create).and_return(customer)
  end

end
