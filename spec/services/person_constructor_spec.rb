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
        with(found_person)
    end

    it "creates new person if none found" do
      params = { email: 'email' }
      new_person = stub_new_person
      stub_new_person_with_remote_fields

      PersonConstructor.new(params).build

      expect(PersonWithRemoteFields).to have_received(:new).
        with(new_person)
    end

    it "assigns appropriate params to person" do
      params = { first_name: 'name', remote_fields: { occupation: 'work' } }
      expected_params = { first_name: 'name', occupation: 'work' }
      stub_new_person
      person = stub_new_person_with_remote_fields

      PersonConstructor.new(params).build

      expect(person).to have_received(:assign_attributes).
        with(expected_params)
    end

    it "assigns location attributes" do
      stub_new_person
      person = stub_new_person_with_remote_fields
      params = { address_1: 'address' }
      constructor = stub_location_constructor(input: params)
      comparer = stub_location_comparer(person: person,
                                        new_params: constructor.attributes)
      allow(person.location).to receive(:assign_attributes)

      PersonConstructor.new(params).build

      expect(person.location).to have_received(:assign_attributes).
        with(comparer.new_attributes)
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
    location = double('location', assign_attributes: nil, attributes: {})
    person = double('person', assign_attributes: nil, location: location)
    allow(PersonWithRemoteFields).to receive(:new).and_return(person)
    person
  end

  def stub_new_person
    person = double('person')
    allow(Person).to receive(:new).and_return(person)
    person
  end

  def stub_location_comparer(person:, new_params:, output: 'comparer attrs')
    comparer = double('comparer', new_attributes: output)
    allow(LocationComparer).to receive(:new).
      with(old: person.location.attributes.symbolize_keys, new: new_params).
      and_return(comparer)
    comparer
  end

  def stub_location_constructor(input:, output: 'constructor attrs')
    constructor = double('constructor', attributes: output)
    allow(LocationConstructor).to receive(:new).
      with(input).
      and_return(constructor)
    constructor
  end
end
