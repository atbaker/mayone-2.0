require 'rails_helper'

describe Ivr::RecordingsController,  type: :controller do

  def setup_active_call_double(fake_url:nil)
    @fake_url = fake_url || "https://website.com/#{SecureRandom.uuid}.mp3"

    person = FactoryGirl.build(:person)
    # allow(person).to receive(:update_remote_attributes)

    recording = double('recording')
    allow(recording).to receive(:recording_url).and_return(@fake_url)

    @active_call = double('active_call')
    allow(@active_call).to receive(:new_record?).and_return(false)
    allow(@active_call).to receive(:campaign_ref).and_return(Ivr::RecordingsController::HOUSE_RECORDING_STRING)
    allow(@active_call).to receive_message_chain(:recordings, :create!).and_return(recording)
    allow(@active_call).to receive(:person).and_return(person)
    allow(Ivr::Call).to receive_message_chain(:includes, :find_or_initialize_by).and_return(@active_call)
  end

  describe "GET start" do
    it "redirects to new_connection" do
      get :start, 'CallSid': 123
      xml_response = Oga.parse_xml(response.body)

      expect(response).to be_success
      expect(xml_response.css('Gather')).to be_present
      expect(xml_response.css('Gather').attribute('method')[0].value).to eq('get')
      expect(xml_response.css('Gather').attribute('action')[0].value).to eq(ivr_recordings_new_recording_url)
    end
    it "plays the senate intro message as default" do
      setup_active_call_double
      allow(@active_call).to receive(:campaign_ref).and_return('someotherrandomstring')

      get :start, 'CallSid': 123
      xml_response = Oga.parse_xml(response.body)

      expect(xml_response.css('Play').text).to include('recording_tool_intro_senate')
    end
    it "plays the house intro message" do
      setup_active_call_double
      get :start, 'CallSid': 123
      xml_response = Oga.parse_xml(response.body)

      expect(xml_response.css('Play').text).to include('recording_tool_intro')
    end
    it "creates a new call when none exists" do
      post_params = {
        CallSid: SecureRandom.uuid,
        RecordingDuration: '123',
        RecordingUrl: "https://fakeurl.com/#{SecureRandom.uuid}.mp3",
        From: '2123121234'
      }

      expect{
        get :start, post_params
        xml_response = Oga.parse_xml(response.body)
      }.to change{ Person.count }
    end
  end

  describe "GET new_recording" do
    subject do
      setup_active_call_double
      get :new_recording, 'CallSid': 123
      Oga.parse_xml(response.body)
    end
    it "renders recording twiml" do
      expect(subject.css('Play').text).to match(/recording_begin_at_beep/)
      expect(subject.css('Record')).to be_present
    end
    it "renders correct action" do
      expect(subject.css('Record').attribute('action')[0].value).to eq(ivr_recordings_re_record_prompt_url)
      expect(subject.css('Record').attribute('finishOnKey')[0].value).to eq('7')
    end
  end

  describe "POST re_record_prompt" do
    before do
      @post_params = {
        CallSid: SecureRandom.uuid,
        RecordingDuration: '123',
        RecordingUrl: "https://fakeurl.com/#{SecureRandom.uuid}.mp3"
      }
    end

    it "creates a new recording with relevant attributes" do
      person = FactoryGirl.create(:person)
      expect{
        post :re_record_prompt, @post_params.merge(From: person.phone)
      }.to change{Ivr::Recording.count}
    end
    context 'the response' do
      before do
        setup_active_call_double(fake_url: @post_params[:RecordingUrl])
      end
      it "plays the new recording" do
        post :re_record_prompt, @post_params
        xml_response = Oga.parse_xml(response.body)

        expect(xml_response.css('Play')).to be_present
        expect(xml_response.css('Play').text).to include(@post_params[:RecordingUrl])
      end
      it "gathers a response to allow re_recording" do
        post :re_record_prompt, @post_params
        xml_response = Oga.parse_xml(response.body)

        expect(xml_response.css('Gather')).to be_present
        expect(xml_response.css('Gather').attribute('action')[0].value).to eq(ivr_recordings_new_recording_url)
      end
    end
  end

end
