class NbCreateDonationJob < ActiveJob::Base
  queue_as :default

  def perform(amount, person_attributes)
    nb_args = Integration::NationBuilder.person_params(person_attributes)
    response = Integration::NationBuilder.create_or_update_person(nb_args) || {}
    person_id = response['id']
    if person_id.present?
      Integration::NationBuilder.create_donation(amount: amount,
                                                 person_id: person_id)
    end
  end
end
