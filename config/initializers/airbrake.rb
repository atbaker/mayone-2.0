Airbrake.configure do |config|
  config.project_key = 'cd590947a7dc5626288c9da2b2baf6e5'
  config.project_id = '110765'
  config.environment = Rails.env
  config.ignore_environments = %w(development test)
end
