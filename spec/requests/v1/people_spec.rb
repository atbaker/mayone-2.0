require "rails_helper"

RSpec.describe "POST /people" do
  include ActiveJob::TestHelper
  it "creates person, updates NB, marks activities complete, and returns uuid" do
    activity = create(:activity)
    zip = create(:zip_code)
    person = create(:person)
    allow(Integration::NationBuilder).to receive(:create_or_update_person)

    perform_enqueued_jobs do
      post "/people", person: { email: person.email, first_name: 'new name',
                                city: 'city', zip: zip.zip_code,
                                remote_fields: { employer: 'work' } },
                      actions: [activity.template_id]
    end

    expected_params = {
      email: person.email, first_name: 'new name', employer: 'work',
      registered_address: {
        city: 'city', state: zip.state.abbrev, zip: zip.zip_code
      }
    }
    expect(Integration::NationBuilder).to have_received(:create_or_update_person).
      with(attributes: expected_params)
    person.reload
    expect(person.first_name).to eq 'new name'
    expect(person.location.city).to eq 'city'
    expect(person.location.state).to eq zip.state
    expect(json_body).to have_key('uuid')
    expect(json_body['uuid']).not_to be_blank
    expect(json_body).to have_key('completed_activities')
    expect(json_body['completed_activities']).to eq [activity.template_id]
  end
end
