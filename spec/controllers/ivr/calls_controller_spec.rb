require 'rails_helper'

describe Ivr::CallsController,  type: :controller do

  def setup_active_call_double(target_legislators:[], new_record:false)
    @active_call = double('active_call')
    person = double('person')
    allow(@active_call).to receive(:person).and_return(!new_record && person || nil)
    allow(@active_call).to receive(:encouraging_count).and_return(1)
    allow(@active_call).to receive(:new_record?).and_return(new_record)
    allow(@active_call).to receive(:target_legislators).and_return(target_legislators)
    allow(@active_call).to receive(:next_target).and_return(target_legislators[0])
    allow(@active_call).to receive(:finished_loop?).and_return(false)
    allow(Ivr::Call).to receive_message_chain(:includes, :find_or_initialize_by).and_return(@active_call)
  end

  def setup_last_connection
    @last_connection = double('last_connection')
    allow(@active_call).to receive(:last_connection).and_return(@last_connection)
    allow(@last_connection).to receive(:update!)
    allow(@last_connection).to receive(:id).and_return(123)
  end

  def legislator_double
    legislator = double('legislator')
    @phone = '555-555-5555'
    allow(legislator).to receive(:phone).and_return(@phone)
    legislator
  end


  describe "setting up active_call" do
    def setup_active_call_with_new_record(new_record: false)
      setup_active_call_double(new_record: new_record)
      setup_last_connection
      allow(@active_call).to receive(:save!)
      allow(@active_call).to receive(:person=)
      allow(Person).to receive(:find_or_initialize_by)
    end
    context "with an existing call" do
      it "does not save a new call" do
        setup_active_call_with_new_record
        post :connection_gather_prompt, 'CallSid': 123, 'DialCallSid': 'abc'

        expect(@active_call).not_to have_received(:save!)
        expect(Person).not_to have_received(:find_or_initialize_by)
      end
    end
    context "without an existing call" do
      it "saves a new call record" do
        setup_active_call_with_new_record(new_record: true)
        post :connection_gather_prompt, 'CallSid': 123, 'DialCallSid': 'abc'

        expect(@active_call).to have_received(:save!)
        expect(Person).to have_received(:find_or_initialize_by)
      end
    end
  end

  describe "GET start" do
    it "redirects to new_connection" do
      get :start, 'CallSid': 123
      xml_response = Oga.parse_xml(response.body)

      expect(response).to be_success
      expect(xml_response.css('Gather')).to be_present
      expect(xml_response.css('Gather').attribute('method')[0].value).to eq('get')
      expect(xml_response.css('Gather').attribute('action')[0].value).to eq(ivr_calls_new_connection_url)
    end
  end

  describe "GET new_connection" do
    context "with a target" do
      before do
        legislator = legislator_double
        setup_active_call_double(target_legislators: [legislator])
        allow(@active_call).to receive(:next_target).and_return(legislator)

        @connection = double('connection')
        allow(@connection).to receive(:connecting_message_key).and_return('connecting_to_senator')
        allow(@active_call).to receive(:create_connection!).and_return(@connection)
        allow(@connection).to receive(:legislator).and_return(legislator)
      end
      it "dials the right number" do
        ClimateControl.modify FAKE_CONGRESS_NUMBER: nil do
          get :new_connection, 'CallSid': 123
          xml_response = Oga.parse_xml(response.body)
          expect(xml_response.css('Dial').text).to eq(@phone)
        end
      end
      it "creates a new connection" do
        get :new_connection, 'CallSid': 123
        expect(@active_call).to have_received(:create_connection!)
      end
      context "with finished loop" do
        it "keeps creating connections" do
          allow(@active_call).to receive(:finished_loop?).and_return(true)
          get :new_connection, 'CallSid': 123
          expect(@active_call).to have_received(:create_connection!)
        end
      end
    end
    context "with finished loop and no more targets" do
      before do
        setup_active_call_double
        legislator = legislator_double
        allow(@active_call).to receive_message_chain(:connections, :size).and_return(5)
        allow(@active_call).to receive(:finished_loop?).and_return(true)
        allow(@active_call).to receive(:next_target).and_return([])
      end

      it "says you're all done" do
        get :new_connection, 'CallSid': 123

        xml_response = Oga.parse_xml(response.body)
        play_text = xml_response.css('Play').text
        say_text = xml_response.css('Say').text

        expect(play_text).not_to match(/closing_message/)
        expect(play_text).not_to match(/there_are_more/)
        expect(say_text).to match(/You\'re all done/)
        expect(play_text).to match(/goodbye/)
      end
    end
    context "with no target" do
      before do
        setup_active_call_double
        allow(@active_call).to receive_message_chain(:connections, :size).and_return(0)
        allow(@active_call).to receive(:next_target).and_return(nil)
      end
      it "says you're all done" do
        get :new_connection, 'CallSid': 123

        xml_response = Oga.parse_xml(response.body)
        play_text = xml_response.css('Play').text
        say_text = xml_response.css('Say').text

        expect(say_text).to match(/You\'re all done/)
        expect(play_text).to match(/goodbye/)
      end
      it "hangs up" do
        get :new_connection, 'CallSid': 123
        xml_response = Oga.parse_xml(response.body)
        expect(xml_response.css('Hangup')).to be_present
      end
    end
  end

  describe "POST connection_gather_prompt" do
    it "updates active_connection with remote_id" do
      setup_active_call_double
      setup_last_connection
      post :connection_gather_prompt, 'CallSid': 123, 'DialCallSid': 'abc', 'DialCallStatus': 'alkjlr2l3'
      expect(@last_connection).to have_received(:update!).with(remote_id:"abc",status: 'alkjlr2l3')
    end
    context do
      subject do
        setup_active_call_double
        setup_last_connection
        post :connection_gather_prompt, 'CallSid': 123, 'DialCallSid': 'abc', 'DialCallStatus': 'alkjlr2l3'
        Oga.parse_xml(response.body)
      end
      it "says a question to gather user response" do
        expect(subject.css('Play').text).to match(/user_response/)
      end
      it "renders a twilio gather with the proper action" do
        action_urls = subject.css('Gather').attribute('action').map(&:value)
        expected_url = ivr_calls_connection_gather_url(connection_id: @last_connection.id)
        expect(action_urls).to include(expected_url)
      end
      it "asks if user is ready for new connection if they don't respond" do
        action_urls = subject.css('Gather').attribute('action').map(&:value)
        expected_url = ivr_calls_new_connection_url
        expect(action_urls).to include(expected_url)
      end
    end
  end

  describe "POST connection_gather" do
    before do
      @connection = double('connection')
      allow(Ivr::Connection).to receive(:find).and_return(@connection)
      allow(@connection).to receive(:update)
      setup_active_call_double
      allow(@active_call).to receive(:encouraging_count).and_return(1)
    end
    it "finds the correct connection" do
      post :connection_gather, 'CallSid': 123, 'Digits': 1, connection_id: 1
      expect(Ivr::Connection).to have_received(:find).with('1')
    end
    it "sets the correct connection status" do
      post :connection_gather, 'CallSid': 123, 'Digits': 1, connection_id: 1
      expect(@connection).to have_received(:update).with(status_from_user: Ivr::Connection::USER_RESPONSE_CODES['1'])
    end
    it "plays an encouraging message if more legislators remain" do
      allow(@active_call).to receive(:encouraging_count).and_return(3)
      allow(@active_call).to receive(:next_target).and_return(true)
      allow(AudioFileFetcher).to receive(:audio_url_for_key)
      post :connection_gather, 'CallSid': 123, 'Digits': 1, connection_id: 1

      xml_response = Oga.parse_xml(response.body)
      expect(xml_response.css('Play')).to be_present
      expect(AudioFileFetcher).to have_received(:audio_url_for_key).with('encouraging_3')
    end
    it "plays an closing message if no more legislators remain" do
      allow(@active_call).to receive(:encouraging_count).and_return(3)
      allow(@active_call).to receive(:next_target).and_return(nil)
      allow(AudioFileFetcher).to receive(:audio_url_for_key)
      post :connection_gather, 'CallSid': 123, 'Digits': 1, connection_id: 1

      xml_response = Oga.parse_xml(response.body)
      target_text = xml_response.css('Say').text
      expect(xml_response.css('Say')).to be_present
      expect(target_text).to match(/You\'re all done/)
    end
    it "redirects to new_connection_path" do
      allow(@active_call).to receive(:next_target).and_return(true)

      post :connection_gather, 'CallSid': 123, 'Digits': 1, connection_id: 1
      xml_response = Oga.parse_xml(response.body)

      expect(xml_response.css('Gather').attribute('method')[0].value).to eq('get')
      expect(xml_response.css('Gather').attribute('action')[0].value).to eq(ivr_calls_new_connection_url)
    end
    context "with a finished_loop" do
      before do
        allow(@active_call).to receive(:finished_loop?).and_return(true)
        legislator = legislator_double
        allow(@active_call).to receive(:next_target).and_return(legislator)
      end

      it "makes closing offer" do
        get :connection_gather, 'CallSid': 123
        target_text = Oga.parse_xml(response.body).css('Play').text
        expect(target_text).to match(/closing_message/)
        expect(target_text).to match(/there_are_more/)
        expect(target_text).to match(/goodbye/)
      end
      it "hangs up" do
        get :connection_gather, 'CallSid': 123
        xml_response = Oga.parse_xml(response.body)
        expect(xml_response.css('Hangup')).to be_present
      end
    end
  end

end
