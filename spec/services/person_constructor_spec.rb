require 'rails_helper'

describe PersonConstructor do
  describe "#build" do
    it "returns a PersonWithRemoteFields" do
      params = { email: 'email' }
      expected_person = stub_new_person_with_remote_fields

      new_person = PersonConstructor.new(params).build

      expect(new_person).to eq expected_person
    end

    it "tries to find person" do
      params = { email: 'email' }
      found_person = stub_person_finder(params: params, found: true)
      stub_new_person_with_remote_fields

      PersonConstructor.new(params).build

      expect(PersonWithRemoteFields).to have_received(:new).
        with(found_person, params)
    end

    it "creates new person if none found" do
      params = { email: 'email' }
      new_person = stub_new_person
      stub_new_person_with_remote_fields

      PersonConstructor.new(params).build

      expect(PersonWithRemoteFields).to have_received(:new).
        with(new_person, params)
    end

    it "normalizes params" do
      params = { address: 'address', remote_fields: { occupation: 'work' } }
      expected_params = { address_1: 'address', occupation: 'work' }
      new_person = stub_new_person
      stub_new_person_with_remote_fields

      PersonConstructor.new(params).build

      expect(PersonWithRemoteFields).to have_received(:new).
        with(new_person, expected_params)
    end
  end

  def stub_person_finder(params:, found:)
    person = found ? double('person') : nil
    finder = double('person finder')
    allow(finder).to receive(:find).and_return(person)
    allow(PersonFinder).to receive(:new).with(params).and_return(finder)
    person
  end

  def stub_new_person_with_remote_fields
    person = double('person')
    allow(PersonWithRemoteFields).to receive(:new).and_return(person)
    person
  end

  def stub_new_person
    person = double('person')
    allow(Person).to receive(:new).and_return(person)
    person
  end
end
