require 'rails_helper'

RSpec.describe Subscription, type: :model do
  it { should validate_presence_of(:remote_id) }
  it { should validate_presence_of(:person) }
end
