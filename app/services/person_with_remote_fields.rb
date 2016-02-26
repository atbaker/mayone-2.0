class PersonWithRemoteFields < SimpleDelegator
  PERSON_FIELDS = [
    :email, :phone, :first_name, :last_name, :is_volunteer
  ]
  LOCATION_FIELDS = [
    :address_1, :address_2, :city, :state_abbrev, :zip
  ]
  REMOTE_FIELDS = [
    :employer, :occupation, :skills, :tags
  ]

  def initialize(person, attributes)
    @attributes = attributes
    person.assign_attributes(person_attributes)
    LocationUpdater.new(person.location, location_attributes).assign
    person.skip_nb_update = true
    super(person)
  end

  def save
    if super
      update_remote
      true
    else
      false
    end
  end

  def person
    __getobj__
  end

  private

  attr_reader :attributes

  def update_remote
    NbPersonPushJob.perform_later(remote_attributes)
  end

  def remote_attributes
    attributes.slice(*(PERSON_FIELDS + LOCATION_FIELDS + REMOTE_FIELDS))
  end

  def person_attributes
    attributes.slice(*PERSON_FIELDS)
  end

  def location_attributes
    attributes.slice(*LOCATION_FIELDS)
  end
end
