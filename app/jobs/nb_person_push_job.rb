class NbPersonPushJob < ActiveJob::Base
  queue_as :default

  def perform(person_attributes)
    event_id = person_attributes.delete(:event_id)
    nb_args = Integration::NationBuilder.person_params(person_attributes)
    response = Integration::NationBuilder.create_or_update_person(attributes: nb_args) || {}
    person_id = response['id']

    if event_id.present? && person_id.present?
      Integration::NationBuilder.create_rsvp(event_id: event_id, person_id: person_id)
    end
  end
end
