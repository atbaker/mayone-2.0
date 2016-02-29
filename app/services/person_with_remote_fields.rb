class PersonWithRemoteFields < SimpleDelegator
  PERSON_FIELDS = [
    :email, :phone, :first_name, :last_name, :is_volunteer
  ]
  REMOTE_FIELDS = [
    :full_name, :employer, :occupation, :skills, :tags
  ]

  def self.permitted_params
    PERSON_FIELDS + REMOTE_FIELDS
  end

  def initialize(person)
    person.skip_nb_update = true
    super(person)
  end

  def save
    if valid?
      update_remote
    end
    super
  end

  def params_for_remote_update
    # TO DO: refactor
    permitted_fields = Integration::NationBuilder::PERMITTED_PERSON_PARAMS
    params = attributes.slice(*changed).
      merge((location.changed - ['person_id']).any? ? location.as_json : {}).
      symbolize_keys.
      slice(*permitted_fields)
    params.any? ? params.merge(email: email) : {}
  end

  def undecorated_person
    __getobj__
  end

  private

  attr_reader :params, :person

  def update_remote
    params = params_for_remote_update
    if params.any?
      NbPersonPushJob.perform_later(params)
    end
  end

  def attributes
    super.merge(remote_attributes)
  end

  def changed
    super + remote_attributes.compact.keys.map(&:to_s)
  end

  def remote_attributes
    REMOTE_FIELDS.map{ |key| [key.to_s, __send__(key)] }.to_h
  end
end
