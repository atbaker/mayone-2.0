require 'rails_helper'

describe V1::DonationsController, type: :controller do

  describe "POST create" do
    it "displays error message if donation processing fails" do
      donation = double('donation', process: false, errors: { foo: ['bad'] })
      allow(Donation).to receive(:new).and_return(donation)

      post :create, bad_param: 'nonsense', person: {email: 'some@email.com'}

      expect(json(response)).to eq({ "error"=> {"foo"=>["bad"]} })
    end
  end

  def json(response)
    JSON.parse(response.body)
  end
end
