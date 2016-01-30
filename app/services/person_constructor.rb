class PersonConstructor
  def initialize(attributes)
    @attributes = attributes.symbolize_keys
    @person = PersonWithRemoteFields.new(find_or_initialize_person, attributes)
  end

  def create
    person.save
    person
  end

  def build
    person
  end

  private

  attr_reader :attributes, :person

  def find_or_initialize_person
    find_person || Person.new
  end

  def find_person
    search_values.each do |key, value|
      search_value = normalize_search_value(key, value)
      person = Person.find_by({ key => search_value })
      return person if person.present?
    end
    nil
  end

  def normalize_search_value(key, value)
    case key
    when :email
      value.downcase
    when :phone
      PhonyRails.normalize_number(value, default_country_code: 'US')
    else
      value
    end
  end

  def search_values
    attributes.slice(:uuid, :email, :phone).compact
  end
end
