require 'rails_helper'

describe V1::GoogleFormsController,  type: :controller do

  describe 'POST create' do
    before do
      person = double('person', save: true)
      allow(person).to receive(:valid?).and_return(true)
      allow(PersonConstructor).to receive(:build).and_return(person)
      allow(GoogleFormsSubmitJob).to receive(:perform_later)

      @google_form_submission_data = {attribute_one: 'first_attribute', attribute_two: 'second_attribute'}
      @google_form_metadata = {
        field_mappings: {attribute_one: 'entry_111', attribute_two: 'entry_222'},
        form_id: 'fake_form_id'
      }
    end

    context 'with a google email mapping' do
      it 'store user and submits to google' do
        fake_email = Faker::Internet.email
        @google_form_metadata[:field_mappings][:email] = 'entry_333'

        post :create,
          person: {email: fake_email },
          google_form_metadata: @google_form_metadata,
          google_form_submission_data: @google_form_submission_data

        expect(PersonConstructor).to have_received(:build).with(email: fake_email)
        expect(GoogleFormsSubmitJob).to have_received(:perform_later).with(
          @google_form_metadata[:form_id],
          {
            @google_form_metadata[:field_mappings][:attribute_one] => @google_form_submission_data[:attribute_one],
            @google_form_metadata[:field_mappings][:attribute_two] => @google_form_submission_data[:attribute_two],
            @google_form_metadata[:field_mappings][:email] => fake_email
          }
        )

        expect(JSON.parse(response.body)['submitted']).to be true
      end
    end

    context 'with no user email' do
      it 'submits to google' do
        post :create,
          google_form_metadata: @google_form_metadata,
          google_form_submission_data: @google_form_submission_data

        expect(GoogleFormsSubmitJob).to have_received(:perform_later)
      end
    end

    context 'with no google_form_submission_data' do
      it 'submits person data to google' do
        fake_email = Faker::Internet.email
        @google_form_metadata[:field_mappings][:email] = 'entry_333'


        post :create,
          person: {email: fake_email },
          google_form_metadata: @google_form_metadata

        expect(GoogleFormsSubmitJob).to have_received(:perform_later).with(
          @google_form_metadata[:form_id],
          {
            @google_form_metadata[:field_mappings][:email] => fake_email
          }
        )
      end
    end
  end

end
