class Integration::Twilio
  require 'twilio-ruby'

  APP_PHONE_NUMBERS = {
    call_congress: ENV['TWILIO_APP_PHONE_NUMBER'],
    record_message: ENV['TWILIO_APP_RECORDING_NUMBER']
  }

  APP_SID_IDS = {
    call_congress: ENV['TWILIO_APP_SID'],
    record_message: ENV['TWILIO_RECORDING_APP_SID']
  }

  def self.initiate_call(phone:, app_key:)
    app_number = APP_PHONE_NUMBERS[app_key]
    app_sid = APP_SID_IDS[app_key]

    rescue_twilio_errors do
      client.calls.create(
        'from' => app_number,
        'to' => phone,
        'ApplicationSid' => app_sid
      )
    end
  end

  def self.end_call(call_sid:)
    call = client.calls.get(call_sid)
    call.hangup
  end

  private

  def self.client
    @@client ||= Twilio::REST::Client.new ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN']
  end

  def self.rescue_twilio_errors
    begin
      yield
    rescue Twilio::REST::RequestError => e
      puts e.inspect
    end
  end

end
