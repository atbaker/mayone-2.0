module Integration
class NationBuilder
  SITE_SLUG = 'mayday'
  SUPPORTER_COUNT_ENDPOINT = '/supporter_counts_for_website'
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
  PERMITTED_PERSON_PARAMS = [
    :email, :phone, :first_name, :last_name, :is_volunteer,
    :full_name, :employer, :occupation, :skills, :tags,
  ] + MAPPINGS_LOCATION.keys

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

  def self.person_params(params)
    # TO DO: refactor
    person = params.symbolize_keys
    address = person.slice(*MAPPINGS_LOCATION.keys)
    if address.any?
      address = rename_keys(address, MAPPINGS_LOCATION)
      person = person.except(*MAPPINGS_LOCATION.keys).
        merge(registered_address: address)
    end
    rename_keys(person, MAPPINGS_PERSON)
  end

  def self.create_person_and_rsvp(event_id:, person_attributes: {}, person_id: nil)
    raise ArgumentError, 'missing :person_id or :person_attributes' if person_id.blank? && (person_attributes.nil? || person_attributes.empty?)
    person_id ||= create_or_update_person(attributes: person_attributes)['id']
    create_rsvp(event_id: event_id, person_id: person_id)
  end

  def self.create_or_update_person(attributes:)
    Rails.logger.info "Pushing person to NationBuilder: #{attributes}"
    response = call_nation_builder(:people, :push, person: attributes)
    response['person']
  end

  def self.create_rsvp(event_id:, person_id:)
    response = call_nation_builder(:events,
                                   :rsvp_create,
                                   site_slug: SITE_SLUG,
                                   id: event_id,
                                   rsvp: { person_id: person_id })
    response['rsvp']
  end

  def self.create_event(attributes:)
    response = call_nation_builder(:events,
                                   :create,
                                   site_slug: SITE_SLUG,
                                   event: attributes)
    response['event'].try(:fetch, 'id')
  end

  def self.destroy_event(id)
    call_nation_builder(:events, :destroy, site_slug: SITE_SLUG, id: id)
  end

  def self.create_donation(amount_in_cents:, person_id:)
    donation = { donor_id: person_id,
                 amount_in_cents: amount_in_cents,
                 payment_type_name: 'Square',
                 succeeded_at: Time.now }
    response = call_nation_builder(:donations, :create, donation: donation)
    response['donation']
  end

  # Public: fetches list counts from a fake NB page with json on it.
  # Nationbuilder page template is only this:
  # {"supporter_count": {{ settings.supporters_count }}, "volunteer_count": {{ settings.volunteers_count }} }
  def self.list_counts
    target_page = ENV['NATION_BUILDER_DOMAIN'] + SUPPORTER_COUNT_ENDPOINT
    JSON.parse(RestClient.get(target_page)).symbolize_keys
  end

  private

  def self.call_nation_builder(*args)
    nb_client.call(*args)
  rescue ::NationBuilder::ClientError => e
    e.message
  end

  def self.nb_client
    @@nb_client ||= ::NationBuilder::Client.new(SITE_SLUG,
                                                ENV['NATION_BUILDER_API_TOKEN'])
  end

  def self.rename_keys(hash, mappings)
    Hash[hash.map {|k, v| [mappings[k] || k, v] }]
  end

end
end
