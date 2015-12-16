# spec/support/fake_nation_builder.rb
require 'sinatra/base'

class FakeNationBuilder < Sinatra::Base

  get '/supporter_counts_for_website' do
    json_response 200, 'lists.json'
  end

  post '/api/v1/donations' do
    json_response 200, 'create_donation.json'
  end

  put '/api/v1/people/push' do
    json_response 200, 'person.json'
  end

  get '/api/v1/people/' do
    json_response 200, 'people.json'
  end

  get '/api/v1/people/match' do
    json_response 200, 'person.json'
  end

  post '/api/v1/sites/mayday/pages/events' do
    json_response 200, 'create_event.json'
  end

  delete '/api/v1/sites/mayday/pages/events/:id' do
    status 204
  end

  post %r{/api/v1/sites/mayday/pages/events/(\d*)/rsvps} do
    json_response 200, 'create_rsvp.json'
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.open(File.dirname(__FILE__) + '/fixtures/nation_builder/' + file_name, 'rb').read
  end
end
