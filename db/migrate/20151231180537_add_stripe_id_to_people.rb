class AddStripeIdToPeople < ActiveRecord::Migration
  def change
    add_column :people, :stripe_id, :string
  end
end
