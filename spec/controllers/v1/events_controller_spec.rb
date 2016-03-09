require 'rails_helper'

describe V1::EventsController,  type: :controller do

  describe "GET index" do
    it "returns success" do
      get :index
      expect(response).to be_success
    end
    it "sets the events variable" do
      event = instance_double("Event")
      expect(Event).to receive(:upcoming) { [event] }
      get :index
      expect(assigns(:events)).to eq [event]
    end
  end

  describe "POST create_rsvp" do
    context "with a person in parameters" do
      before do
        @activity = FactoryGirl.create(:activity, template_id: Activity::DEFAULT_TEMPLATE_IDS[:rsvp])
        @person = FactoryGirl.build(:person)
        allow(@person).to receive(:create_action)
        allow(PersonConstructor).to receive(:build).and_return(@person)
      end

      it "returns success" do
        allow(Integration::NationBuilder).to receive(:create_person_and_rsvp)

        post :create_rsvp, event_id: 5, person: {email: 'dude@gmail.com'}

        expect(response).to be_success
      end

      it "stores an action with the right params" do
        allow(Integration::NationBuilder).to receive(:create_person_and_rsvp)
        action_params = {
          utm_source: 'expected_source',
          utm_medium: 'expected_medium',
          utm_campaign: 'expected_campaign',
          source_url: 'expected_url',
          template_id: @activity.template_id
        }

        post :create_rsvp, {
          event_id: 5,
          person: {email: @person.email, first_name: @person.first_name}
        }.merge(action_params.except(:template_id))

        expect(@person).to have_received(:create_action).with(action_params)
      end
      it "pushes remote_fields to create_or_update" do
        allow(Integration::NationBuilder).to receive(:create_person_and_rsvp)
        person_params = {email: @person.email, first_name: @person.first_name, remote_fields: {tags: ['20150501_test_tag'], skills: 'I have skills'}}

        post :create_rsvp, {
          event_id: 5,
          person: person_params
        }

        expect(Integration::NationBuilder).to have_received(:create_person_and_rsvp).
          with(event_id: '5', person_attributes: @person.attributes.symbolize_keys)
      end
    end
    context "with missing person parameters" do
      it "returns success" do
        post :create_rsvp, event_id: 5
        expect(response).not_to be_success
        expect(JSON.parse(response.body)).to have_key('error')
      end
    end
  end
end
