class PersonConstructor
  KEY_NAME_MAPPINGS = {
    address: :address_1,
    zip: :zip_code,
  }
  OLD_REMOTE_FIELDS = [
    remote_fields: [:event_id, :employer, :occupation, :skills, tags: []]
  ]
  PERSON_FIELDS = [
    :email, :phone, :first_name, :last_name, :is_volunteer
  ]
  REMOTE_FIELDS = [
    :full_name, :employer, :occupation, :skills, :tags
  ]
  LOCATION_FIELDS = Location::PERMITTED_PARAMS + [:state_abbrev]

  def self.permitted_params
    PersonWithRemoteFields.permitted_params +
      LOCATION_FIELDS +
      KEY_NAME_MAPPINGS.keys +
      OLD_REMOTE_FIELDS
  end

  def initialize(params)
    @params = params.deep_symbolize_keys
    normalize_params
  end

  def build
    person = find_or_initialize_person_with_remote_fields
    person.assign_attributes(person_params)
    person.location.merge(location_params)
    person.location.fill_in_missing_attributes
    person
  end

  private

  attr_reader :params

  def find_or_initialize_person_with_remote_fields
    # need to allow uuid?
    if person = PersonFinder.new(params).find
      person.becomes(PersonWithRemoteFields)
    else
      PersonWithRemoteFields.new
    end
  end

  def normalize_params
    flatten_remote_fields
    rename_keys
    strip_whitespace_from_values
  end

  def flatten_remote_fields
    params.merge!(params.delete(:remote_fields) || {})
  end

  def strip_whitespace_from_values
    params.merge!(params){ |k, v1| v1.try(:strip) || v1 }
  end

  def rename_keys
    renameable_keys.each do |key|
      params[ KEY_NAME_MAPPINGS[key] ] = params.delete(key)
    end
  end

  def renameable_keys
    params.keys & KEY_NAME_MAPPINGS.keys
  end

  def person_params
    params.slice(*PersonWithRemoteFields.permitted_params)
  end

  def location_params
    params.slice(*LOCATION_FIELDS)
  end
end
