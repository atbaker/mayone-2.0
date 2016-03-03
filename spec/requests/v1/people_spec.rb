require "rails_helper"

RSpec.describe "POST /people" do
  include ActiveJob::TestHelper

  before do
    Integration::NationBuilder.class_variable_set :@@nb_client, nil
  end

  it "creates/updates person, updates NB, marks activities complete, returns uuid" do
    activity = create(:activity)
    zip = create(:zip_code)
    person = create(:person)
    nb_client = stub_nation_builder_client

    perform_enqueued_jobs do
      post "/people", person: { email: person.email, first_name: 'new name',
                                city: 'city', zip: zip.zip_code,
                                remote_fields: { employer: 'work' } },
                      actions: [activity.template_id]
    end

    expect(nb_client).to have_received(:call).with(:people, :push, person: {
      email: person.email, first_name: 'new name', employer: 'work',
      registered_address: {
        address1: nil, address2: nil, city: 'city', state: zip.state.abbrev,
        zip: zip.zip_code
      }
    })
    person.reload
    expect(person.first_name).to eq 'new name'
    expect(person.location.city).to eq 'city'
    expect(person.location.state).to eq zip.state
    expect(json_body).to have_key('uuid')
    expect(json_body['uuid']).not_to be_blank
    expect(json_body).to have_key('completed_activities')
    expect(json_body['completed_activities']).to eq [activity.template_id]
  end

  def stub_nation_builder_client
    client = spy('client')
    allow(NationBuilder::Client).to receive(:new).
      with(Integration::NationBuilder::SITE_SLUG,
           ENV['NATION_BUILDER_API_TOKEN']).
      and_return(client)
    client
  end
end
