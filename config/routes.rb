Rails.application.routes.draw do
  api_version(module: "V1", path: {value: "v1"}, default: true, defaults: {format: :json}) do
    resources :legislators, only: [:index, :show], param: :bioguide_id do
      get :targeted, on: :collection
      get :newest_supporters, on: :collection
      get :supporters_map, on: :collection, defaults: {format: :js}
    end
    resources :people, only: :create do
      get :targets, on: :collection, action: :targets
      post :targets, on: :collection, action: :targets
      get '/:identifier', on: :collection, action: :show, constraints: { identifier: /[^\/]+/} #allow email as identifier
    end
    resources :payments,    only: :create
    resources :stats,       only: :index
    resources :actions,     only: :create do
      get :count, on: :collection
    end
    resources :activities,  only: :index

    resources :google_forms, only: :create

    namespace :ivr do
      resources :calls, only: :create
    end

    resources :events,  only: :index do
      post :create_rsvp, on: :collection
    end
    resources :blog_posts, only: :index do
      get :press_releases, on: :collection
    end
    get '/people/targets', to: 'people#targets'
    get '/bills/:id/supporter_counts', to: 'bills#supporter_counts'
    get '/bills/supporter_counts', to: 'bills#supporter_counts'
    get '/bills/:id/timeline', to: 'bills#timeline'
    get '/bills/timeline', to: 'bills#timeline'

  end

  namespace :ivr do
    post '/calls/start',                    to: 'calls#start'
    get  '/calls/new_connection',           to: 'calls#new_connection'
    post '/calls/connection_gather_prompt', to: 'calls#connection_gather_prompt'
    post '/calls/connection_gather',        to: 'calls#connection_gather'

    post '/recordings/start',            to: 'recordings#start'
    get '/recordings/new_recording',     to: 'recordings#new_recording'
    post '/recordings/re_record_prompt', to: 'recordings#re_record_prompt'
  end


  require 'sidekiq/api'
  get "/queue-status" => proc { [200, {"Content-Type" => "text/plain"}, [Sidekiq::Queue.new.size < 100 ? "OK" : "UHOH" ]] }
  get "/queue-latency" => proc { [200, {"Content-Type" => "text/plain"}, [Sidekiq::Queue.new.latency < 30 ? "OK" : "UHOH" ]] }
end
