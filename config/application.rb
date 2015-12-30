rails_loading_start = Time.now

require File.expand_path('../boot', __FILE__)

require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mayday
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    config.serve_static_files = false

    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths += ["#{Rails.root}/lib}"]

    #this works on most hosts, but not on heroku.  heroku config is in config.ru
    config.middleware.insert_before 0, "Rack::Cors", :debug => false, :logger => (-> { Rails.logger }) do
      allow do
        origins '*'
        resource '*',
          :headers => :any,
          :methods => [:put, :post, :get, :options]
      end
    end

    redis_host = ENV['REDIS_URL'] || ENV['REDISTOGO_URL']
    if redis_host
      config.cache_store = :redis_store, redis_host, { expires_in: 6.hours }
    end

    config.middleware.use Rack::Deflater
  end
end

puts "Rails loaded in #{Time.now-rails_loading_start}s running Ruby #{RUBY_VERSION}" if Rails.env.test? || Rails.env.development?
