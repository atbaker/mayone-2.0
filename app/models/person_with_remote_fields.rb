class PersonWithRemoteFields < Person
  PERSON_FIELDS = [
    :email, :phone, :first_name, :last_name, :is_volunteer
  ]
  REMOTE_PARAMS = [
    :event_id, :employer, :occupation, skills: [], tags: []
  ]
  REMOTE_FIELDS = REMOTE_PARAMS.map { |key| key.try(:keys) || key }.flatten

  attr_accessor *REMOTE_FIELDS

  def self.permitted_fields
    PERSON_FIELDS + REMOTE_FIELDS
  end

  def self.permitted_params
    PERSON_FIELDS + REMOTE_PARAMS
  end

  def save(args = {})
    self.skip_nb_update = true
    if valid?
      update_remote
    end
    super # will try to save location, but won't complain if it can't
  end

  def params_for_remote_update
    if all_params.any?
      all_params.merge(identifier)
    else
      {}
    end
  end

  private

  def update_remote
    if params_for_remote_update.any?
      NbPersonPushJob.perform_later(params_for_remote_update)
    end
  end

  def identifier
    if email.present?
      { email: email }
    else
      { phone: phone }
    end
  end

  def all_params
    attributes.slice(*changed).
      merge(remote_attributes.compact).
      merge(location_params).
      symbolize_keys.
      slice(*Integration::NationBuilder::PERMITTED_PERSON_PARAMS)
  end

  def remote_attributes
    REMOTE_FIELDS.map { |key| [key.to_s, __send__(key)] }.to_h
  end

  def location_params
    if (location.changed & Location::ADDRESS_FIELDS.map(&:to_s)).any?
      location.as_json  # maybe dangerous to reuse serializable_hash here?
    else
      {}
    end
  end
end
