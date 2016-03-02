require 'phony_rails'
# == Schema Information
#
# Table name: people
#
#  id           :integer          not null, primary key
#  email        :string
#  phone        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  first_name   :string
#  last_name    :string
#  uuid         :string
#  is_volunteer :boolean
#

class Person < ActiveRecord::Base
  has_one :subscription
  has_one :location, dependent: :destroy
  has_one :district, through: :location
  has_one :representative, through: :district
  has_one :target_rep, -> { targeted }, through: :district
  has_one :state, through: :location
  has_many :senators, through: :state
  has_many :calls, class_name: 'Ivr::Call', dependent: :destroy
  has_many :connections, through: :calls
  has_many :recordings, through: :calls
  has_many :all_called_legislators, through: :calls, source: :called_legislators
  has_many :donation_pages, dependent: :destroy
  has_many :actions, dependent: :destroy
  has_many :activities, through: :actions

  validates :email, uniqueness: { case_sensitive: false },
    email_format: { message: 'is invalid' },
    allow_nil: true

  validates :email, presence: true, unless: :phone
  validates :phone, presence: true, unless: :email
  phony_normalize :phone, default_country_code: 'US'

  before_create :generate_uuid, unless: :uuid?
  before_save :downcase_email
  after_save :update_nation_builder, unless: :skip_nb_update

  scope :identify, -> identifier {
    includes(:actions)
    .where('email = :identifier OR uuid = :identifier OR phone = :identifier', identifier: identifier)
  }

  alias_method :location_association, :location
  delegate :update_location, :district, :state, to: :location

  FIELDS_ALSO_ON_NB = %w[email first_name last_name is_volunteer phone]
  PERMITTED_PUBLIC_FIELDS = [:email, :phone, :first_name, :last_name, :full_name, :address, :city, :state_abbrev, :zip, :is_volunteer, remote_fields: [:event_id, :employer, :occupation, :skills, tags: []]]
  LOCATION_ATTRIBUTES = [:address, :zip, :city, :state_abbrev]
  DEFAULT_TARGET_COUNT = 100

  SUPPLEMENTARY_ATTRIBUTES = [:remote_fields, :full_name] + LOCATION_ATTRIBUTES
  ALL_AVAILABLE_ATTRIBUTES = PERMITTED_PUBLIC_FIELDS + LOCATION_ATTRIBUTES
  attr_accessor *SUPPLEMENTARY_ATTRIBUTES, :skip_nb_update

  def self.create_or_update(person_params)
    person = PersonConstructor.new(person_params).build
    person.save
    person
  end

  def self.new_uuid
    SecureRandom.uuid
  end

  def location
    location_association || build_location
  end

  def mark_activities_completed(template_ids)
    Activity.where(template_id: template_ids).each do |activity|
      actions.create(activity: activity)
    end
  end

  def last_initial
    last_name.to_s.first
  end

  def completed_activities
    actions.joins(:activity).pluck("activities.template_id")
  end

  def address_required?
    district.blank?
  end

  def legislators
    (district || state).try(:legislators)
  end

  def constituent_of?(legislator)
    legislators && legislators.include?(legislator)
  end

  def unconvinced_local_legislators
    legislators && legislators.unconvinced.eligible
  end

  def targeted_local_legislators(campaign_id: nil)
    if campaign_id.nil?
      legislators && unconvinced_local_legislators.default_targeted
    else
      local_legislators_targeted_by(campaign_id: campaign_id)
    end
  end

  def local_legislators_targeted_by(campaign_id:)
    legislators && legislators.unconvinced.eligible.targeted_by_campaign(campaign_id)
  end

  def other_targets(count:, excluding:, campaign_id: nil)
    legislators_scope = Legislator.includes(:current_bills).with_includes
    if campaign_id.nil?
      legislators_scope.default_targeted
    else
      legislators_scope.targeted_by_campaign(campaign_id)
    end.where.not(id: excluding.map(&:id)).limit(count) || []
  end

  def target_legislators(json: false, count: DEFAULT_TARGET_COUNT, campaign_id: nil)
    locals = targeted_local_legislators(campaign_id: campaign_id) || []
    remaining_count = count - locals.length
    others = other_targets(count: remaining_count, excluding: locals, campaign_id: campaign_id)
    if json
      locals.as_json(extras: { local: true }) + others.as_json(extras: { local: false })
    else
      locals + others
    end
  end

  def completed_activity?(activity)
    completed_activity_ids.include?(activity.id)
  end

  def completed_activity_ids
    @completed_activity_ids ||= activity_ids
  end

  def activities_hash
    Activity.order(:id).map do |activity|
      {
        name: activity.name,
        order: activity.sort_order,
        completed: completed_activity?(activity),
        template_id: activity.template_id
      }
    end
  end

  def error_message_output
    !valid? && errors.full_messages.join('. ') + '.'
  end

  def create_action(params)
    params.symbolize_keys!
    if activity = Activity.find_or_create_by(template_id: params[:template_id])
      action_params = params.slice(:utm_source, :utm_medium, :utm_campaign,
                                   :source_url, :donation_amount_in_cents)
      actions.create!(action_params.merge(activity: activity))
    end
  end

  def merge!(other)
    raise "cannot merge with a new record" if other.new_record?
    raise "cannot merge with myself" if other == self

    #merge associations
    (%w[calls actions]).each do |association_name|
      send(association_name).concat other.send(association_name)
    end

    #merge attributes
    updated_attributes = other.attributes.compact!.merge(attributes.compact!)
    update(updated_attributes)
    location_attrs = updated_attributes.slice(LOCATION_ATTRIBUTES)
    update_location(location_attrs) if location_attrs.any?

    #cleanup
    other.reload.destroy
    save!
  end

  def self.merge_duplicates!(records, compare_on:)
    records.each do |record|
      next if record.nil?
      records.each do |other|
        next if other.nil?
        next if other == record
        next if other.send(compare_on).blank? || record.send(compare_on).blank?
        is_comparable = other.send(compare_on) == record.send(compare_on)
        next unless is_comparable

        #merge and remove the other
        records[records.index(other)]=nil
        record.merge!(other)
      end
    end.compact
  end

  def self.update_nation_builder_call_counts!
    select(:phone,:email,:id).includes(:connections).find_each do |person|
      person.set_remote_call_counts!
    end
  end

  def set_remote_call_counts!
    remote_fields = {representative_call_attempts: representative_call_attempts, representative_calls_count: representative_calls_count}
    update_remote_attributes(remote_fields) if representative_call_attempts > 0
  end

  def representative_call_attempts
    connections.length
  end

  def representative_calls_count
    connections.completed.count
  end

  def update_remote_attributes(remote_attributes)
    self.remote_fields ||= {}
    remote_fields.merge!(remote_attributes)
    update_nation_builder
  end

  private

  def update_nation_builder
    relevant_fields = changed & FIELDS_ALSO_ON_NB
    if relevant_fields.any? || remote_fields.present?
      nb_attributes = self.slice(:email, :phone, *relevant_fields).merge(remote_fields || {}).compact
      NbPersonPushJob.perform_later(nb_attributes.symbolize_keys)
    end
  end

  def downcase_email
    email && self.email = email.downcase
  end

  def generate_uuid
    self.uuid = self.class.new_uuid
  end
end
