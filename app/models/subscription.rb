class Subscription < ActiveRecord::Base
  belongs_to :person, required: true

  validates :remote_id, presence: true
end
