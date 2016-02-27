class PersonConstructor
  KEY_NAME_MAPPINGS = {
    address: :address_1,
    zip: :zip_code,
  }

  OLD_REMOTE_FIELDS = [
    remote_fields: [:event_id, :employer, :occupation, :skills, tags: []]
  ]

  def self.permitted_fields
    PersonWithRemoteFields.permitted_fields +
      KEY_NAME_MAPPINGS.keys +
      OLD_REMOTE_FIELDS
  end

  def initialize(attributes)
    @attributes = attributes.deep_symbolize_keys
    normalize_attributes
  end

  def build
    PersonWithRemoteFields.new(find_or_initialize_person, attributes)
  end

  private

  attr_reader :attributes

  def find_or_initialize_person
    PersonFinder.new(attributes).find || Person.new
  end

  def normalize_attributes
    flatten_remote_fields
    rename_keys
    strip_whitespace_from_values
  end

  def flatten_remote_fields
    attributes.merge!(attributes.delete(:remote_fields) || {})
  end

  def rename_keys
    renameable_keys.each do |key|
      attributes[ KEY_NAME_MAPPINGS[key] ] = attributes.delete(key)
    end
  end

  def renameable_keys
    attributes.keys & KEY_NAME_MAPPINGS.keys
  end

  def strip_whitespace_from_values
    attributes.merge!(attributes){ |k, v1| v1.try(:strip) || v1 }
  end
end
