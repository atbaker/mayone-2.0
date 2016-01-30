class PersonWithRemoteFields < SimpleDelegator
  REMOTE_FIELDS = [
    :email, :phone, :first_name, :last_name, :is_volunteer,
    :employer, :occupation, :skills, :tags
  ]
  LOCAL_FIELDS = [
    :email, :phone, :first_name, :last_name,
    :address, :city, :state_abbrev, :zip, :is_volunteer
  ]

  def initialize(person, attributes)
    remote_fields = attributes.symbolize_keys.delete(:remote_fields) || {}
    @attributes = attributes.merge(remote_fields).symbolize_keys
    person.assign_attributes(local_attributes)
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
    attributes.slice(*REMOTE_FIELDS)
  end

  def local_attributes
    attributes.slice(*LOCAL_FIELDS)
  end
end
