class PersonWithRemoteFields < Person
  REMOTE_STRINGS = [:event_id, :employer, :occupation]
  REMOTE_ARRAYS = [:skills, :tags]
  REMOTE_FIELDS = REMOTE_STRINGS + REMOTE_ARRAYS
  REMOTE_PARAMS = REMOTE_STRINGS + REMOTE_ARRAYS.map { |k| { k => [] } }
  ALL_FIELDS = Person::PERMITTED_PARAMS + REMOTE_FIELDS

  attr_accessor *REMOTE_FIELDS

  def save(args = {})
    if valid?
      update_remote
    end
    super
  end

  def params_for_remote_update
    if all_params.any?
      all_params.merge(identifier)
    else
      {}
    end
  end

  def custom_fields
    @_custom_fields ||= {}
  end

  def custom_fields=(fields)
    custom_fields.merge!(fields)
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
      slice(*Integration::NationBuilder::PERMITTED_PERSON_PARAMS).
      merge(custom_fields)
  end

  def remote_attributes
    REMOTE_FIELDS.map { |key| [key.to_s, __send__(key)] }.to_h
  end

  def location_params
    if location && (location.changed & Location::ADDRESS_FIELDS.map(&:to_s)).any?
      location.as_json  # maybe dangerous to reuse serializable_hash here?
    else
      {}
    end
  end
end
