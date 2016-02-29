require 'rails_helper'

describe PersonWithRemoteFields do
  describe "#params_for_remote_update" do
    it "returns changed attributes" do
      person = PersonWithRemoteFields.new(Person.new)
      person.email = 'email'

      params = person.params_for_remote_update

      expect(params).to eq(email: 'email')
    end

    it "excludes attributes not relevant to CRM" do
      person = PersonWithRemoteFields.new(Person.new)
      person.updated_at = Time.now

      params = person.params_for_remote_update

      expect(params).to eq({})
    end

    it "always includes email" do
      person = PersonWithRemoteFields.new(Person.new)
      person.first_name = 'name'

      params = person.params_for_remote_update

      expect(params).to eq(email: nil, first_name: 'name')
    end

    it "includes remote attributes" do
      person = PersonWithRemoteFields.new(Person.new)
      person.employer = 'work'

      params = person.params_for_remote_update

      expect(params).to eq(email: nil, employer: 'work')
    end

    it "includes location attributes" do
      person = PersonWithRemoteFields.new(Person.new)
      person.location.zip_code = '01111'

      params = person.params_for_remote_update

      expect(params).to include(email: nil, zip_code: '01111')
    end

    it "converts state to string" do
      person = PersonWithRemoteFields.new(Person.new)
      state = create(:state)
      person.location.state = state

      params = person.params_for_remote_update

      expect(params).to include(email: nil, state_abbrev: state.abbrev)
    end

    it "symbolizes keys" do
      person = PersonWithRemoteFields.new(Person.new)
      person.assign_attributes(first_name: 'name', occupation: 'job')

      params = person.params_for_remote_update

      expect(params.keys).to match_array [:email, :first_name, :occupation]
    end
  end

  describe "#save" do
    context "with valid person" do
      it "updates remote if applicable fields changed" do
        allow(NbPersonPushJob).to receive(:perform_later)
        person = PersonWithRemoteFields.new(Person.new)
        person.assign_attributes(email: 'user@example.com', tags: ['test'])

        person.save

        expect(NbPersonPushJob).to have_received(:perform_later).
          with(email: 'user@example.com', tags: ['test'])
      end

      it "doesn't update remote if no applicable fields changed" do
        allow(NbPersonPushJob).to receive(:perform_later)
        person = PersonWithRemoteFields.new(create(:person))
        person.updated_at += 1.hour

        person.save

        expect(NbPersonPushJob).not_to have_received(:perform_later)
      end
    end

    context "with invalid person" do
      it "doesn't update remote" do
        allow(NbPersonPushJob).to receive(:perform_later)
        person = PersonWithRemoteFields.new(Person.new)
        person.assign_attributes(occupation: 'work')

        person.save

        expect(NbPersonPushJob).not_to have_received(:perform_later)
      end
    end
  end
end
