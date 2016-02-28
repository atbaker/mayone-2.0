class PersonWithRemoteFields < SimpleDelegator
  PERSON_FIELDS = [
    :email, :phone, :first_name, :last_name, :is_volunteer
  ]
  REMOTE_FIELDS = [
    :full_name, :employer, :occupation, :skills, :tags
  ]
  LOCATION_FIELDS = Location::PERMITTED_PARAMS + [:state_abbrev]

  def self.permitted_params
    PERSON_FIELDS + LOCATION_FIELDS + REMOTE_FIELDS
  end

  def initialize(person, params)
    @params = params
    @person = person
    person.assign_attributes(person_params)
    person.location.assign_attributes(location_attributes)
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

  attr_reader :params, :person

  def location_attributes
    @_location_attributes ||= if location_params.any?
                                get_location_attributes
                              else
                                {}
                              end
  end

  def get_location_attributes
    LocationComparer.new(
      old: person.location.attributes.symbolize_keys,
      new: LocationConstructor.new(location_params).attributes
    ).new_attributes
  end

  def update_remote
    NbPersonPushJob.perform_later(remote_params)
  end

  def remote_params
    params.slice(*self.class.permitted_params).
      merge(state_abbrev_from_location_attributes)
  end

  def state_abbrev_from_location_attributes
    if params[:state_abbrev].blank? && state = location_attributes[:state]
      { state_abbrev: state.abbrev }
    else
      {}
    end
  end

  def person_params
    params.slice(*PERSON_FIELDS)
  end

  def location_params
    params.slice(*LOCATION_FIELDS)
  end
end
