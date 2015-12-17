class NbPersonPushJob < ActiveJob::Base
  queue_as :default

  def perform(person_attributes)
    event_id = person_attributes.delete(:event_id)
    donation_amount = person_attributes.delete(:donation_amount)
    nb_args = Integration::NationBuilder.person_params(person_attributes)
    response = Integration::NationBuilder.create_or_update_person(nb_args) || {}
    person_id = response['id']

    if person_id.present?
      if event_id.present?
        Integration::NationBuilder.create_rsvp(event_id: event_id, person_id: person_id)
      end
      if donation_amount.present?
        Integration::NationBuilder.create_donation(amount: donation_amount,
                                                   person_id: person_id)
      end
    end
  end
end
