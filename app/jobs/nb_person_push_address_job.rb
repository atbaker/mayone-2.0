class NbPersonPushAddressJob < ActiveJob::Base
  queue_as :default

  def perform(email, location)
    nb_args = Integration::NationBuilder.location_params(email: email, location: location)
    Integration::NationBuilder.create_or_update_person(attributes: nb_args)
  end
end
