class ChangeDonationAmount < ActiveRecord::Migration
  def change
    change_column :actions, :donation_amount, :integer
    rename_column :actions, :donation_amount, :donation_amount_in_cents
  end
end
