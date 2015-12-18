class Integration::Stripe
  def self.generate_token
    Stripe::Token.create(
      :card => {
        :number => "4242424242424242",
        :exp_month => 12,
        :exp_year => 2016,
        :cvc => "314"
      },
    )
  end
end
