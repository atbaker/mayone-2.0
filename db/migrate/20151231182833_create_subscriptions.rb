class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.belongs_to :person, index: true, null: false
      t.string :remote_id, null: false
    end
    add_foreign_key :subscriptions, :people
  end
end
