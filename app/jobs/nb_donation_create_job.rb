class NbDonationCreateJob < ActiveJob::Base
  queue_as :default

  def perform(amount_in_cents, person_attributes)
    nb_args = Integration::NationBuilder.person_params(person_attributes)
    response = Integration::NationBuilder.create_or_update_person(attributes: nb_args) || {}
    person_id = response['id']

    Integration::NationBuilder.create_donation(amount_in_cents: amount_in_cents,
                                               person_id: person_id)
  end
end
