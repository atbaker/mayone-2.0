class PersonConstructor
  KEY_NAME_MAPPINGS = {
    address: :address_1,
  }

  def initialize(attributes)
    @attributes = attributes.deep_symbolize_keys
  end

  def build
    PersonWithRemoteFields.new(find_or_initialize_person, cleaned_attributes)
  end

  private

  attr_reader :attributes

  def find_or_initialize_person
    PersonFinder.new(attributes).find || Person.new
  end

  def cleaned_attributes
    rename_keys_and_strip_values(flatten_remote_fields(attributes))
  end

  def flatten_remote_fields(attributes)
    attributes.except(:remote_fields).merge(attributes[:remote_fields] || {})
  end

  def rename_keys_and_strip_values(attributes)
    Hash[attributes.map{|k, v| [rename_key(k), strip_value(v)] }]
  end

  def rename_key(key)
    KEY_NAME_MAPPINGS[key] || key
  end

  def strip_value(value)
    value.try(:strip) || value
  end
end
