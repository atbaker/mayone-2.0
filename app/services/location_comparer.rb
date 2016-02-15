class LocationComparer
  def initialize(old_city: nil, old_state: nil, old_zip: nil,
                 new_city: nil, new_state: nil, new_zip: nil)
    @old_city = old_city
    @old_state = old_state
    @old_zip = old_zip
    @new_city = new_city
    @new_state = new_state
    @new_zip = new_zip
  end

  def different?
    different_zip? || different_state? || different_city?
  end

  private

  attr_reader :old_city, :old_state, :old_zip, :new_city, :new_state, :new_zip

  def different_zip?
    new_zip && new_zip != old_zip
  end

  def different_city?
    new_city && old_city && new_city != old_city
  end

  def different_state?
    new_state && new_state != old_state
  end
end
