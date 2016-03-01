require 'rails_helper'

describe PersonConstructor do
  describe "#build" do
    it "returns a PersonWithRemoteFields" do
      params = { email: 'email' }
      stub_person_finder(params)

      new_person = PersonConstructor.new(params).build

      expect(new_person).to be_a PersonWithRemoteFields
    end

    it "tries to find person" do
      params = { email: 'email' }
      found_person = stub_person_finder(params)

      new_person = PersonConstructor.new(params).build

      expect(new_person.id).to eq found_person.id
    end

    it "creates new person if none found" do
      params = { email: 'email' }
      stub_person_finder(params, found: false)
      expected_person = stub_new_person_with_remote_fields

      new_person = PersonConstructor.new(params).build

      expect(new_person).to eq expected_person
    end

    it "assigns appropriate params to person" do
      params = { first_name: 'name', occupation: 'work' }
      stub_person_finder(params)

      person = PersonConstructor.new(params).build

      expect(person.first_name).to eq 'name'
      expect(person.occupation).to eq 'work'
    end

    it "normalizes params for PersonWithRemoteFields" do
      params = { first_name: 'name', remote_fields: { occupation: 'work' } }
      expected_params = { first_name: 'name', occupation: 'work' }
      stub_person_finder(expected_params)

      person = PersonConstructor.new(params).build

      expect(person.first_name).to eq 'name'
      expect(person.occupation).to eq 'work'
    end

    it "assigns location attributes" do
      params = { address: 'address' }
      expected_params = { address_1: 'address' }
      person = stub_person_finder(expected_params)
      allow(person).to receive(:becomes).and_return(person)
      allow(person.location).to receive(:merge)
      allow(person.location).to receive(:fill_in_missing_attributes)

      PersonConstructor.new(params).build

      expect(person.location).to have_received(:merge).
        with(expected_params)
      expect(person.location).to have_received(:fill_in_missing_attributes)
    end
  end

  def stub_person_finder(params, found: true)
    person = found ? build_stubbed(:person) : nil
    finder = double('person finder')
    allow(finder).to receive(:find).and_return(person)
    allow(PersonFinder).to receive(:new).with(params).and_return(finder)
    person
  end

  def stub_new_person_with_remote_fields
    person = spy('person')
    allow(PersonWithRemoteFields).to receive(:new).
      with(no_args).
      and_return(person)
    person
  end

  # def stub_location_comparer(person:, new_params:, output: 'comparer attrs')
  #   comparer = double('comparer', new_attributes: output)
  #   allow(LocationComparer).to receive(:new).
  #     with(old: person.location.attributes.symbolize_keys, new: new_params).
  #     and_return(comparer)
  #   comparer
  # end

  # def stub_location_constructor(input:, output: 'constructor attrs')
  #   constructor = double('constructor', attributes: output)
  #   allow(LocationConstructor).to receive(:new).
  #     with(input).
  #     and_return(constructor)
  #   constructor
  # end
end
