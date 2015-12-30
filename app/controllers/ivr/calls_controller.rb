class Ivr::CallsController < Ivr::ApplicationController
  require 'twilio-ruby'

  # Public: initiates the call process via a request from twillio
  #
  # CallSid - default param from twilio (optional)
  def start
    response = Twilio::TwiML::Response.new do |r|
      r.Pause
      play_audio(r, 'intro_message')
      ready_for_connection?(r)
      close_call(r)
    end

    render_twiml response
  end

  # Public: initiates a new outgoing call to congress. If ENV FAKE_CONGRESS_NUMBER is
  # set, then the all calls will be routed to that number.
  #
  # CallSid - default param from twilio (required)
  def new_connection
    response = Twilio::TwiML::Response.new do |r|
      if active_call.next_target.present?
        connection = active_call.create_connection!
        play_audio(r, connection.connecting_message_key)
        play_audio(r, 'star_to_disconnect')
        target_number = ENV['FAKE_CONGRESS_NUMBER'] || connection.legislator.phone
        r.Dial target_number, 'action' => ivr_calls_connection_gather_prompt_url, 'hangupOnStar' => true, 'callerId' => caller_id
      else
        close_call(r)
      end
    end

    render_twiml response
  end

  # Public: prompts a user reported response on how the connection preformed
  #
  # CallSid - active_call's remote_id from twilio(required)
  # DialCallSid - dialed call's remote_id from twilio (required)
  def connection_gather_prompt
    active_connection = active_call.last_connection
    active_connection.update!(remote_id: params['DialCallSid'], status: params['DialCallStatus'])
    response = Twilio::TwiML::Response.new do |r|
      r.Pause(length:2) #prevents user from accidentaly pushing * for this gather prompt
      r.Gather(
        action: ivr_calls_connection_gather_url(connection_id: active_connection.id),
        'numDigits' => 1,
        'finishOnKey' => ''
      ) do |gather|
        play_audio(r, 'user_response')
        gather.Pause(length:5)
        play_audio(r, 'user_response')
      end
      ready_for_connection?(r)
    end

    render_twiml response
  end

  # Public: gathers the user response on connection preformance
  #
  # CallSid - active_call's remote_id from twilio (required)
  # Digits - the key pressed user response from twilio (required)
  # connection_id - remote_for the target connection (required)
  def connection_gather
    active_connection = Ivr::Connection.find(params[:connection_id])
    active_connection.update(status_from_user: Ivr::Connection::USER_RESPONSE_CODES[params['Digits']])
    response = Twilio::TwiML::Response.new do |r|
      if active_call.finished_loop?  || active_call.next_target.nil?
        close_call(r)
      else
        r.Play AudioFileFetcher.encouraging_audio_for_count(active_call.encouraging_count)
        ready_for_connection?(r)
        close_call(r)
      end
    end

    render_twiml response
  end

  private

  def ready_for_connection?(twilio_renderer)
    twilio_renderer.Gather(action: ivr_calls_new_connection_url, method: 'get', 'numDigits' => 1) do |gather|
      play_audio(twilio_renderer, 'press_star_to_continue')
      3.times do
        gather.Pause(length: 5)
        play_audio(twilio_renderer, 'press_star_to_continue')
      end
    end
  end

  def close_call(twilio_renderer)
    if active_call.finished_loop? || active_call.next_target.nil?
      if active_call.next_target.present?
        twilio_renderer.Gather(action: ivr_calls_new_connection_url, method: 'get') do |gather|
          play_audio(twilio_renderer, 'closing_message')
          3.times do
            play_audio(twilio_renderer, 'there_are_more')
            gather.Pause(length: 7)
          end
        end
      else
        twilio_renderer.Say('You\'re all done. Thanks for supporting fundamental reform of the way elections are funded.')
      end
    end
    play_audio(twilio_renderer, 'goodbye')
    twilio_renderer.Hangup
  end

  def caller_id
    @caller_id ||= set_caller_id
  end

  def set_caller_id
    if params['To'] && params['Caller'] !~ /client/
      params['To']
    else
      Integration::Twilio::APP_PHONE_NUMBERS[:call_congress]
    end
  end

end