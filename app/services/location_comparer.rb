class LocationComparer
  def initialize(old_city: nil, old_state: nil, old_zip_code: nil,
                 new_city: nil, new_state: nil, new_zip_code: nil)
    @old_city = old_city
    @old_state = old_state
    @old_zip_code = old_zip_code
    @new_city = new_city
    @new_state = new_state
    @new_zip_code = new_zip_code
  end

  def different?
    different_zip? || different_state? || different_city?
  end

  private

  attr_reader :old_city, :old_state, :old_zip_code,
    :new_city, :new_state, :new_zip_code

  def different_zip?
    new_zip_code && new_zip_code != old_zip_code
  end

  def different_city?
    new_city && old_city && new_city != old_city
  end

  def different_state?
    new_state && new_state != old_state
  end
end
