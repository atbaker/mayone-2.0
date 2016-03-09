class PersonConstructor
  KEY_NAME_MAPPINGS = {
    address: :address_1,
    zip: :zip_code,
  }
  OLD_REMOTE_PARAMS = [
    remote_fields: PersonWithRemoteFields::REMOTE_PARAMS
  ]

  def self.permitted_params
    Person::PERMITTED_PARAMS | PersonFinder::SEARCH_KEYS +
      PersonWithRemoteFields::REMOTE_PARAMS +
      Location::PERMITTED_PARAMS +
      KEY_NAME_MAPPINGS.keys +
      OLD_REMOTE_PARAMS
  end

  def self.build(params)
    normalized_params = normalize_params(params)
    person = find_or_initialize_person_with_remote_fields(normalized_params)
    person.assign_attributes(person_fields(normalized_params))
    assign_location_attributes(person, location_fields(normalized_params))
    person
  end

  private

  attr_reader :params

  def self.find_or_initialize_person_with_remote_fields(params)
    if person = PersonFinder.new(params).find
      person.becomes(PersonWithRemoteFields)
    else
      PersonWithRemoteFields.new
    end
  end

  def self.assign_location_attributes(person, location_params)
    if location_params.any?
      new_location = LocationComparable.new(location_params)
      person.location.becomes(LocationComparable).merge(new_location)
      person.location.set_missing_attributes
    end
  end

  def self.normalize_params(params)
    strip_whitespace_from_values(
      normalize_keys(
        flatten_remote_fields(
          params.deep_symbolize_keys
        )
      )
    )
  end

  def self.flatten_remote_fields(params)
    params.except(:remote_fields).merge(params[:remote_fields] || {})
  end

  def self.strip_whitespace_from_values(params)
    params.map { |k, v| [k, v.try(:strip) || v] }.to_h
  end

  def self.normalize_keys(params)
    params.map { |k, v| [KEY_NAME_MAPPINGS[k] || k, v] }.to_h
  end

  def self.person_fields(params)
    params.slice(*PersonWithRemoteFields::ALL_FIELDS)
  end

  def self.location_fields(params)
    params.slice(*Location::PERMITTED_PARAMS)
  end
end
