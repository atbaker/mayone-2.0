require 'rails_helper'

describe PersonWithRemoteFields do
  describe ".new" do
    it "applies attributes to given person" do
      person = Person.new

      person_with_remote_fields = PersonWithRemoteFields
        .new(person, last_name: 'smith')

      expect(person_with_remote_fields).to eq person
      expect(person_with_remote_fields.last_name).to eq 'smith'
    end
  end

  describe "#save" do
    context "with valid params" do
      it "returns true" do
        person = PersonWithRemoteFields.new(Person.new, attributes_for(:person))

        response = person.save

        expect(response).to be true
      end

      it "updates remote" do
        allow(NbPersonPushJob).to receive(:perform_later)
        person = PersonWithRemoteFields.
          new(Person.new, email: 'user@example.com',
                          tags: ['test'])

        person.save

        expect(NbPersonPushJob).to have_received(:perform_later).
          with(email: 'user@example.com', tags: ['test'])
      end
    end

    context "with invalid params" do
      it "returns false" do
        person = PersonWithRemoteFields.new(Person.new, {})

        response = person.save

        expect(response).to be false
      end

      it "doesn't update remote" do
        allow(NbPersonPushJob).to receive(:perform_later)
        person = PersonWithRemoteFields.
          new(Person.new, occupation: 'work')

        person.save

        expect(NbPersonPushJob).not_to have_received(:perform_later)
      end
    end
  end
end
