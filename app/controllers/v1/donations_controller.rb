class V1::DonationsController < V1::BaseController

  # Receives person, payment and action attributes. Creates/updates a person
  # creates an action, and creates a stripe single or recurring payment
  # Params:
  #  * person - hash - person hash
  #  * employer - string - person employer
  #  * occupation - string - person occupation
  #  * amount_in_cents - int - donation amount in cents
  #  * recurring - true - pass true if recurring donation
  #  * stripe_token - token returned by Stripe.js to identify credit card
  #  * template_id - action template_id
  #  * utm_source - action utm_source
  #  * utm_medium - action utm_medium
  #  * utm_campaign - action utm_campaign
  #  * source_url - action source_url
  def create
    person = PersonConstructor.new(person_params).build.tap(&:save) # temporary fix
    donation = Donation.new(donation_params.merge(person: person))
    if donation.process
      render json: { status: 'success' }
    else
      render json: { error: donation.errors }
    end
  end

  private

  def donation_params
    params.permit(:employer, :occupation, :stripe_token, :recurring,
                  :amount_in_cents, :utm_source, :utm_medium, :utm_campaign,
                  :source_url, :template_id)
  end

  def person_params
    params.require(:person).permit(PersonConstructor.permitted_params)
  end
end
