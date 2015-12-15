require 'rails_helper'

describe V1::PaymentsController, type: :controller do

  describe "POST create" do
    it "works" do
      stub_stripe_charge(amount: 400, source: 'test token', charge_id: 'test id')
      post :create, payment: { amount: 400, source: 'test token' }
      expect(json(response)['charge_id']).to eq 'test id'
    end
  end

end

def json(response)
  JSON.parse(response.body)
end

def stub_stripe_charge(amount: 100, source: 'token', charge_id: 'id')
  charge = double('charge', id: charge_id)
  allow(Stripe::Charge).to receive(:create).
    with(hash_including(
      'amount' => amount.to_s,
      'source' => source,
      'currency' => 'usd')).
    and_return(charge)
end
