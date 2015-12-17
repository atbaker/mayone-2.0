class V1::PaymentsController < V1::BaseController

  def create

    charge = Stripe::Charge.create(payment_params)

    person = Person.create_or_update(person_params)

    person.create_action(action_params.symbolize_keys)

    render json: { status: 'success' }

  rescue Stripe::CardError => e
    render json: { error: e.message }
  end

  private

  def action_params
    amount = payment_params['amount'].to_f/100.0
    params.permit(:template_id, :utm_source, :utm_medium, :utm_campaign, :source_url).
      merge(donation_amount: amount)
  end

  def person_params
    person = params.require(:person).permit(Person::PERMITTED_PUBLIC_FIELDS)
    amount = payment_params['amount']
    payment_info = { remote_fields: { donation_amount: amount } }
    person.deep_merge(payment_info)
  end

  def payment_params
    defaults = {
      'currency' => 'usd',
      'description' => 'donation from test@example.com'
    }

    defaults.merge(params.permit(:amount, :source))
  end
end
