class V1::PaymentsController < V1::BaseController

  def create

    charge = Stripe::Charge.create(payment_params)

    render json: { charge_id: charge.id }

  rescue Stripe::CardError => e
    render json: { error: e.message }
  end

  private

  def payment_params
    defaults = {
      'currency' => 'usd',
      'description' => 'donation from test@example.com'
    }

    defaults.merge(params.require(:payment).permit(:amount, :source))
  end
end
