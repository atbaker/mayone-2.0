class PersonFinder
  def initialize(attributes)
    @attributes = attributes
  end

  def find
    search_values.each do |key, value|
      search_value = normalize_search_value(key, value)
      person = Person.find_by({ key => search_value })
      return person if person.present?
    end
    nil
  end

  private

  attr_reader :attributes

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
