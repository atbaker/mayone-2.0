source 'https://rubygems.org'
ruby '2.2.4'

gem 'rails', '4.2.0'
gem 'pg'
gem 'redis'
gem 'redis-objects'
gem 'redis-rails'
gem 'database_cleaner'
gem 'phony_rails', :require => false

# Active Job
gem 'sidekiq'
gem 'sinatra' # Used for the sidekiq UI

# API consuming
gem 'rest-client', :require => false
gem 'oauth2'
gem 'twilio-ruby', :require => false

# API publishing
gem 'rails-api'
gem 'jbuilder', '~> 2.0'
gem 'versionist'
gem 'rack-cors', :require => 'rack/cors'
gem 'oj'

# SysOps + Monitoring
group :production do
  gem 'rails_12factor'  # Heroku-required
  gem 'newrelic_rpm'
end
gem 'unicorn'
gem 'airbrake'

# Payment processing
gem 'stripe'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :development, :test do
  gem 'byebug'
  gem 'web-console', '~> 2.0'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'dotenv-rails'
  gem 'rspec-rails'
  gem 'hirb'
end

group :development do
  gem 'annotate', '>=2.6.0'
  gem 'rack-mini-profiler'
  gem 'bullet'
end

group :test do
  gem 'codeclimate-test-reporter'
  gem 'climate_control'
  gem 'oga' #xml parsing
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'webmock'
  gem 'fakeredis', :require => 'fakeredis/rspec'
  gem 'timecop'
  gem 'shoulda-matchers'
end

