class PersonConstructor
  def initialize(attributes)
    @attributes = attributes.symbolize_keys
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
    Hash[attributes.map{|k, v| [k, v.try(:strip) || v] }]
  end
end
