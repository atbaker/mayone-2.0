class Donation
  include ActiveModel::Model

  attr_accessor :person, :employer, :occupation, :stripe_token, :recurring,
    :utm_source, :utm_medium, :utm_campaign, :source_url, :amount_in_cents

  attr_writer :template_id

  validates :person, presence: true
  validates :employer, presence: true
  validates :occupation, presence: true
  validates :stripe_token, presence: true
  validates :amount_in_cents, presence: true,
    numericality: { greater_than: 0, only_integer: true }

  def process
    if valid?
      process_payment
      record_donation
      create_donate_action
    else
      false
    end

  rescue Stripe::CardError, Stripe::InvalidRequestError => e
    errors.add(:stripe_token, e.json_body[:error][:message])
    false
  end

  private

  def process_payment
    if ActiveRecord::Type::Boolean.new.type_cast_from_user(recurring)
      stripe_customer = StripeCustomer.new(create_stripe_customer)
      person.update(stripe_id: stripe_customer.id)
      person.create_subscription(remote_id: stripe_customer.subscription_id)
    else
      create_stripe_charge
    end
  end

  def record_donation
    person = { email: self.person.email, employer: employer, occupation: occupation }
    NbDonationCreateJob.perform_later(amount_as_integer, person)
  end

  def create_donate_action
    person.create_action(utm_source: utm_source,
                         utm_medium: utm_medium,
                         utm_campaign: utm_campaign,
                         source_url: source_url,
                         template_id: template_id,
                         donation_amount_in_cents: amount_as_integer)
  end

  def template_id
    @template_id ||= Activity::DEFAULT_TEMPLATE_IDS[:donate]
  end


  def create_stripe_customer
    Stripe::Customer.create(source: stripe_token,
                            plan: 'one_dollar_monthly',
                            email: person.email,
                            quantity: amount_as_integer/100)
  end

  def create_stripe_charge
    Stripe::Charge.create(amount: amount_as_integer,
                          source: stripe_token,
                          currency: 'usd',
                          description: "donation from #{self.person.email}")
  end

  def amount_as_integer
    amount_in_cents.to_i
  end

  class StripeCustomer
    attr_reader :id, :subscription_id

    def initialize(stripe_customer)
      @id = stripe_customer.id
      @subscription_id = stripe_customer.subscriptions.first.id
    end
  end
end
