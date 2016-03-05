require 'rails_helper'

describe V1::Ivr::CallsController,  type: :controller do

  describe "#create" do
    before do
      @target_phone = '1-123-123-1234'
      @fake_sid = 'werl1l2312'
      call = FactoryGirl.build(:call, remote_id: @fake_sid)

      @person = double('person', save: true)
      allow(@person).to receive(:create_action)
      allow(@person).to receive_message_chain(:calls, :create).and_return(call)
      allow(@person).to receive_message_chain(:phone).and_return(@target_phone)
      constructor = double('constructor', build: @person)
      allow(PersonConstructor).to receive(:new).and_return(constructor)

      twilio_call = double('twilio_call')
      allow(twilio_call).to receive(:sid).and_return(@fake_sid)
      allow(Integration::Twilio).to receive(:initiate_call).and_return(twilio_call)
    end
    it "initates a twilio call" do
      expected_key = :call_congress
      post :create, person: { phone: @target_phone }
      expect(Integration::Twilio).to have_received(:initiate_call).with(phone: @target_phone, app_key: expected_key)
    end
    it "initates a twilio call for recording voicemails" do
      expected_key = :record_message
      post :create, person: { phone: @target_phone }, call_type: 'record_message'
      expect(Integration::Twilio).to have_received(:initiate_call).with(phone: @target_phone, app_key: expected_key)
    end
    it "returns the twilio call sid" do
      post :create, person: { phone: @target_phone }
      json_response = JSON.parse(response.body)
      expect(json_response['call_sid']).to include(@fake_sid)
    end
    it "stores an activity with the right params" do
      activity = FactoryGirl.create(:activity, template_id: Activity::DEFAULT_TEMPLATE_IDS[:call_congress])
      post_params = {
        utm_source: 'expected_source',
        utm_medium: 'expected_medium',
        utm_campaign: 'expected_campaign',
        source_url: 'expected_url'
      }

      expected_params = {template_id: activity.template_id}.merge(post_params)
      post :create, {person: {phone: @target_phone}}.merge(post_params)
      expect(@person).to have_received(:create_action).with(expected_params)
    end

    context "with bad params" do
      it "returns the twilio call sid" do
        post :create, phone: @target_phone
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
      end
    end
  end
end
