module Integration
class NationBuilder

  STANDARD_HEADERS = {'Accept' => 'application/json', 'Content-Type' => 'application/json'}
  ENDPOINTS = {
    list_count_page: '/supporter_counts_for_website',
    event:           '/api/v1/sites/mayday/pages/events/%s',
    events:          '/api/v1/sites/mayday/pages/events',
    donations:       '/api/v1/donations',
    people:          '/api/v1/people/push',
    people_by_email: '/api/v1/people/match?email=%s',
    rsvps_by_event:  '/api/v1/sites/mayday/pages/events/%s/rsvps'
  }
  ALLOWED_PARAMS_EVENT = [:slug, :status, :name, :start_time, :end_time,
    autoresponse: [:broadcaster_id, :subject, :body]]
  ALLOWED_PARAMS_PERSON = [:birthdate, :do_not_call, :first_name, :last_name, :email, :email_opt_in, :employer, :is_volunteer,
    :mobile_opt_in, :mobile, :occupation, :phone, :recruiter_id, :sex, :request_ip, :skills, :rootstrikers_subscription, :uuid,
    :pledge_page_slug, :fundraising, :email_subscription, :maydayin30_entry_url, :voting_district_id, :map_lookup_district,
    :representative_call_attempts, :representative_calls_count, :voter_calls_count, :recorded_message_url,
    :recorded_message_20150611_s1538, :recorded_message_20150329_hr20,
    registered_address: [:address1, :address2, :city, :state, :zip], tags: []]
  MAPPINGS_PERSON = {
    email: nil,
    phone: nil
  }
  MAPPINGS_LOCATION = {
    address_1:    :address1,
    address_2:    :address2,
    city:         nil,
    state_abbrev: :state,
    zip_code:     :zip
  }

  def self.event_params(start_time:, end_time:)
    event = {
      slug: "test_orientation_" + start_time.to_formatted_s(:number),
      name: "Mayday Call Campaign Orientation",
      start_time: start_time,
      end_time: end_time,
      status: "unlisted",
      autoresponse: {
        broadcaster_id: 1,
        subject: "Mayday orientation confirmation"
      }
    }
    { attributes: event }
  end

  def self.person_params(person)
    person = rename_keys(person.symbolize_keys, MAPPINGS_PERSON)
    { attributes: person }
  end

  def self.location_params(email:, location:)
    address = rename_keys(location.symbolize_keys, MAPPINGS_LOCATION)
    { attributes: { email: email, registered_address: address } }
  end

  def self.query_people_by_email(email)
    rescue_oauth_errors do
      response = request_handler(endpoint_path: ENDPOINTS[:people_by_email] % email)
      response['person']
    end
  end

  def self.create_person_and_rsvp(event_id:, person_attributes: {}, person_id: nil)
    raise ArgumentError, 'missing :person_id or :person_attributes' if person_id.blank? && (person_attributes.nil? || person_attributes.empty?)
    person_id ||= create_or_update_person(attributes: person_attributes)['id']
    create_rsvp(event_id: event_id, person_id: person_id)
  end

  def self.create_or_update_person(attributes:)
    rescue_oauth_errors do
      body = {'person': parse_person_attributes(attributes).compact}
      Rails.logger.info "Pushing person to NationBuilder: #{body}"
      response = request_handler(endpoint_path: ENDPOINTS[:people], body: body, method: 'put')
      response['person']
    end
  end

  def self.list_events
    rescue_oauth_errors do
      response = request_handler(endpoint_path: ENDPOINTS[:events], method: 'get')
      Rails.logger.warn 'finished create or update person with params'

      response
    end
  end

  def self.create_donation(amount:, person_id:)
    rescue_oauth_errors do
      body = { 'donation': { donor_id: person_id,
                             amount_in_cents: amount,
                             payment_type_name: 'Square',
                             succeeded_at: Time.now } }
      response = request_handler(endpoint_path: ENDPOINTS[:donations], body: body, method: 'post')
      response['donation']
    end
  end

  def self.create_rsvp(event_id:, person_id:)
    rescue_oauth_errors do
      body = {'rsvp': {'person_id': person_id}}
      response = request_handler(endpoint_path: ENDPOINTS[:rsvps_by_event] % event_id, body: body, method: 'post')
      response['rsvp']
    end
  end

  def self.create_event(attributes:)
    rescue_oauth_errors do
      body = {'event': parse_event_attributes(attributes)}
      response = request_handler(endpoint_path: ENDPOINTS[:events], body: body, method: 'post')
      response['event'].try(:fetch, 'id')
    end
  end

  def self.destroy_event(id)
    rescue_oauth_errors do
      response = token.send('delete', ENDPOINTS[:event] % id)
      response.status == 204
    end
  end

  # Public: fetches list coutns from a fake NB page with json on it.
  # Nationbuilder page template is only this:
  # {"supporter_count": {{ settings.supporters_count }}, "volunteer_count": {{ settings.volunteers_count }} }
  def self.list_counts
    target_page = ENV['NATION_BUILDER_DOMAIN'] + ENDPOINTS[:list_count_page]
    JSON.parse(RestClient.get(target_page)).symbolize_keys
  end

  private

  def self.request_handler(method: 'get', endpoint_path:, body: {})
    response = token.send(method, endpoint_path, body: body.to_json, headers: STANDARD_HEADERS)
    JSON.parse(response.body)
  end

  def self.rescue_oauth_errors
    begin
      yield
    rescue OAuth2::Error => e
      case e.response.parsed['code']
      when 'no_matches', 'not_found'
        nil
      when 'validation_failed'
        e.response.parsed['validation_errors'][0]
      else
        e.response.parsed['message']
      end
    end
  end

  def self.client
    @@client ||= OAuth2::Client.new(ENV['NATION_BUILDER_ID'], ENV['NATION_BUILDER_SECRET'], site: 'https://'+ENV['NATION_BUILDER_DOMAIN'])
  end

  def self.token
    @@token ||= OAuth2::AccessToken.new(client, ENV['NATION_BUILDER_API_TOKEN'])
  end

  def self.parse_person_attributes(raw_parameters)
    parameters = ActionController::Parameters.new(raw_parameters)
    parameters.permit(ALLOWED_PARAMS_PERSON)
  end

  def self.parse_event_attributes(raw_parameters)
    parameters = ActionController::Parameters.new(raw_parameters)
    parameters.permit(ALLOWED_PARAMS_EVENT)
  end

  def self.rename_keys(hash, mappings)
    Hash[hash.map {|k, v| [mappings[k] || k, v] }]
  end

end
end
