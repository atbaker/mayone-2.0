class V1::PaymentsController < V1::BaseController

  def create

    person = Person.create_or_update(person_params)

    if recurring?
      response = Stripe::Customer.create(subscription_params)
      customer_id = response.id
      subscription_id = response.subscriptions.data.first.id
      person.update(stripe_id: customer_id)
      person.create_subscription(remote_id: subscription_id)
    else
      Stripe::Charge.create(payment_params)
    end

    person.create_action(action_params.symbolize_keys)

    render json: { status: 'success' }

  rescue Stripe::CardError => e
    render json: { error: e.message }
  end

  private

  def recurring?
    params[:recurring].presence
  end

  def amount_in_cents
    payment_params['amount'].to_i
  end

  def donor_email
    person_params[:email]
  end

  def action_params
    params.permit(:template_id, :utm_source, :utm_medium, :utm_campaign, :source_url).
      merge(donation_amount_in_cents: amount_in_cents)
  end

  def person_params
    payment_info = { remote_fields: { donation_amount: amount_in_cents } }
    params.require(:person).permit(Person::PERMITTED_PUBLIC_FIELDS).
      deep_merge(payment_info)
  end

  def payment_params
    defaults = {
      currency: 'usd',
      description: 'donation from #{donor_email}'
    }

    defaults.merge(params.permit(:amount, :source))
  end

  def subscription_params
    defaults = {
      plan: "one_dollar_monthly",
      email: donor_email,
      quantity: amount_in_cents/100
    }

    defaults.merge(params.permit(:source))
  end

end
