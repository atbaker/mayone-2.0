ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
Dotenv.load(".env.example")

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

require "fakeredis"
redis_opts = {url: ENV['REDIS_URL'] || ENV['REDISTOGO_URL'], size: 1}
redis_opts.merge!(driver: Redis::Connection::Memory) if defined?(Redis::Connection::Memory)

Sidekiq.configure_client do |config|
  config.redis = redis_opts
end


RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include FactoryGirl::Syntax::Methods

  config.before(:each) do
    stub_request(:any, /#{Integration::PledgeService::PLEDGE_SERVICE_DOMAIN}/).to_rack(FakePledgeService)
    stub_request(:any, /#{ENV['NATION_BUILDER_DOMAIN']}/).to_rack(FakeNationBuilder)
    stub_request(:any, /#{Integration::MobileCommons::DOMAIN}/).to_rack(FakeMobileCommons)
    stub_request(:any, /#{Integration::Here::DOMAIN}/).to_rack(FakeHere)
    stub_request(:any, /#{Integration::Sunlight::DOMAIN}/).to_rack(FakeSunlight)
    stub_request(:any, /#{Integration::RepsWithUs::DOMAIN}/).to_rack(FakeRepsWithUs)
  end

  config.before(:suite) do
    DatabaseCleaner.clean_with :deletion
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
