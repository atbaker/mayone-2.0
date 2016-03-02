# == Schema Information
#
# Table name: zip_codes
#
#  id             :integer          not null, primary key
#  zip_code       :string
#  city           :string
#  state_id       :integer
#  district_count :integer
#  on_house_gov   :boolean
#  last_checked   :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class ZipCode < ActiveRecord::Base
  belongs_to :state, required: true
  has_many :senators, through: :state
  has_many :target_senators, -> { targeted }, through: :state
  has_and_belongs_to_many :districts
  has_many :representatives, through: :districts
  has_many :target_reps, -> { targeted }, through: :districts
  has_many :campaigns, through: :districts

  validates :zip_code, presence: true, uniqueness: { case_sensitive: false },
      format: { with: /\A\d{5}\z/ }

  def self.valid_zip?(string)
    /\A(?<zip>\d{5})[^\w]?(\d{4})?\z/ =~ string
  end

  def self.find_by_zip(zip)
    find_by(zip_code: zip.first(5))
  end

  def single_district?
    districts.size == 1
  end

  def single_district
    districts.first if single_district?
  end

  def targeted?
    target_reps.any?
  end

  def targeted_by_campaign?(campaign)
    campaigns.include?(campaign)
  end

end
