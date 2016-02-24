require 'rails_helper'

describe PersonFinder do
  it "finds by uuid, if present" do
    params = { email: 'email', phone: 'phone', uuid: 'uuid' }
    expected_person = stub_person_find_by(uuid: 'uuid')

    found_person = PersonFinder.new(params).find

    expect(found_person).to eq expected_person
  end

  it "finds by email if uuid not present" do
    params = { email: 'email', phone: 'phone' }
    expected_person = stub_person_find_by(email: 'email')

    found_person = PersonFinder.new(params).find

    expect(found_person).to eq expected_person
  end

  it "finds by phone if uuid and email not present" do
    params = { other: 'other', phone: '+15555555555' }
    expected_person = stub_person_find_by(phone: '+15555555555')

    found_person = PersonFinder.new(params).find

    expect(found_person).to eq expected_person
  end

  it "downcases email" do
    params = { email: 'EMAIL' }
    expected_person = stub_person_find_by(email: 'email')

    found_person = PersonFinder.new(params).find

    expect(found_person).to eq expected_person
  end

  it "nomalizes phone number" do
    params = { phone: 'phone' }
    stub_phone_normalize(input: 'phone', output: 'normalized phone')
    expected_person = stub_person_find_by(phone: 'normalized phone')

    found_person = PersonFinder.new(params).find

    expect(found_person).to eq expected_person
  end

  it "tries all search keys until it finds a person" do
    params = { phone: 'phone', email: 'email', uuid: 'uuid' }
    allow(Person).to receive(:find_by).and_return(nil)

    PersonFinder.new(params).find

    expect(Person).to have_received(:find_by).exactly(3).times
  end

  it "returns nil if person not found" do
    params = { uuid: 'unrecognized' }

    found_person = PersonFinder.new(params).find

    expect(found_person).to be nil
  end

  it "returns nil if no search values provided" do
    params = { other: 'other' }
    allow(Person).to receive(:find_by)

    found_person = PersonFinder.new(params).find

    expect(Person).not_to have_received(:find_by)
    expect(found_person).to be nil
  end

  def stub_person_find_by(args)
    person = double('person')
    allow(Person).to receive(:find_by).with(args).and_return(person)
    person
  end

  def stub_phone_normalize(input:, output:)
    allow(PhonyRails).to receive(:normalize_number).
      with(input, default_country_code: 'US').
      and_return(output)
  end
end
