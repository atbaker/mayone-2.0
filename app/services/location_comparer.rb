class LocationComparer
  def initialize(old:, new:)
    @old = old
    @new = new
  end

  def different?
    no_old_address? || different_zip? || different_state? || different_city?
  end

  def new_attributes
    if different?
      blank_address.merge(new)
    else
      new.compact
    end
  end

  private

  attr_reader :old, :new

  def no_old_address?
    old.slice(:city, :state, :zip_code).empty?
  end

  def different_zip?
    new[:zip_code] && new[:zip_code] != old[:zip_code]
  end

  def different_city?
    new[:city] && old[:city] && new[:city] != old[:city]
  end

  def different_state?
    new[:state] && new[:state] != old[:state]
  end

  def blank_address
    Hash[Location::PERMITTED_PARAMS.map{|k| [k, nil]}]
  end
end
