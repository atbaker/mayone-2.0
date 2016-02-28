class PersonWithRemoteFields < SimpleDelegator
  PERSON_FIELDS = [
    :email, :phone, :first_name, :last_name, :is_volunteer
  ]
  REMOTE_FIELDS = [
    :full_name, :employer, :occupation, :skills, :tags
  ]
  LOCATION_FIELDS = Location::PERMITTED_PARAMS + [:state_abbrev]

  def self.permitted_fields
    PERSON_FIELDS + LOCATION_FIELDS + REMOTE_FIELDS
  end

  def initialize(the_person, attributes)
    @attributes = attributes
    @person = the_person
    person.assign_attributes(person_attributes)
    person.location.assign_attributes(new_location_attributes)
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

  def without_remote_fields
    __getobj__
  end

  private

  attr_reader :attributes, :person

  def new_location_attributes
    if location_attributes.any?
      @_new_location_attributes ||= get_new_location_attributes
    else
      {}
    end
  end

  def get_new_location_attributes
    new_location = LocationConstructor.new(location_attributes)
    comparer = LocationComparer.new(old: person.location.attributes.symbolize_keys,
                                    new: new_location.attributes)
    comparer.new_attributes
  end

  def update_remote
    NbPersonPushJob.perform_later(remote_attributes)
  end

  def remote_attributes
    if state = new_location_attributes[:state]
      state_hash = { state_abbrev: state.abbrev }
    end
    attributes.slice(*self.class.permitted_fields).
      merge(state_hash || {})
  end

  def person_attributes
    attributes.slice(*PERSON_FIELDS)
  end

  def location_attributes
    attributes.slice(*LOCATION_FIELDS)
  end
end
