require 'sinatra/base'

class FakeStripe < Sinatra::Base
  post '/v1/charges' do
    json_response 200, 'charge.json'
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.open(File.dirname(__FILE__) + '/fixtures/stripe/' + file_name, 'rb').read
  end
end
