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

  def initialize(attributes)
    @attributes = attributes.deep_symbolize_keys
    normalize_attributes
  end

  def build
    person = find_or_initialize_person_with_remote_fields
    person.assign_attributes(person_params)
    person.location.assign_attributes(location_attributes(person))
    person
  end

  private

  attr_reader :attributes

  def find_or_initialize_person_with_remote_fields
    if person = PersonFinder.new(attributes).find
      person.becomes(PersonWithRemoteFields)
    else
      PersonWithRemoteFields.new
    end
  end

  def normalize_attributes
    flatten_remote_fields
    rename_keys
    strip_whitespace_from_values
  end

  def flatten_remote_fields
    attributes.merge!(attributes.delete(:remote_fields) || {})
  end

  def strip_whitespace_from_values
    attributes.merge!(attributes){ |k, v1| v1.try(:strip) || v1 }
  end

  def rename_keys
    renameable_keys.each do |key|
      attributes[ KEY_NAME_MAPPINGS[key] ] = attributes.delete(key)
    end
  end

  def renameable_keys
    attributes.keys & KEY_NAME_MAPPINGS.keys
  end

  def person_params
    attributes.slice(*PersonWithRemoteFields.permitted_params)
  end

  def location_attributes(person)
    @_location_attributes ||= if location_params.any?
                                get_location_attributes(person)
                              else
                                {}
                              end
  end

  def get_location_attributes(person)
    LocationComparer.new(
      old: person.location.attributes.symbolize_keys,
      new: LocationConstructor.new(location_params).attributes
    ).new_attributes
  end

  def location_params
    attributes.slice(*LOCATION_FIELDS)
  end
end
