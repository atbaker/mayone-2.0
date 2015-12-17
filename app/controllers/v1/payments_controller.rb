class V1::PaymentsController < V1::BaseController

  def create

    charge = Stripe::Charge.create(payment_params)

    Person.create_or_update(person_params)

    render json: { charge_id: charge.id }

  rescue Stripe::CardError => e
    render json: { error: e.message }
  end

  private

  def person_params
    person = params.require(:person).permit(Person::PERMITTED_PUBLIC_FIELDS)
    payment = { remote_fields: { donation_amount: payment_params['amount'] } }
    person.deep_merge(payment)
  end

  def payment_params
    defaults = {
      'currency' => 'usd',
      'description' => 'donation from test@example.com'
    }

    defaults.merge(params.require(:payment).permit(:amount, :source))
  end
end
