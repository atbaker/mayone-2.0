require 'rails_helper'

describe V1::PaymentsController, type: :controller do

  describe "POST create" do
    it "works" do
      post :create, payment: { amount: 400, source: 'tok_17Hea72GrfzlbO4XCqtqUYli' }
      expect(json(response)['charge_id']).to eq 'ch_178e5F2GrfzlbO4XnVTNBJdq'
    end
  end

end

def json(response)
  JSON.parse(response.body)
end
