Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
  secret_key:      ENV['STRIPE_SECRET_KEY'],
  api_version:     "2016-02-19"
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
