# == Schema Information
#
# Table name: districts
#
#  id         :integer          not null, primary key
#  district   :string
#  state_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class District < ActiveRecord::Base
  belongs_to :state, required: true
  has_many :senators, through: :state
  has_and_belongs_to_many :zip_codes
  has_one :representative, class_name: "Legislator", dependent: :destroy
  has_one :target_rep, -> { targeted }, class_name: "Legislator"
  has_many :campaigns, through: :representative

  validates :district, presence: true, uniqueness: { scope: :state }

  delegate :abbrev, to: :state

  def self.find_by_state_and_district(state:, district:)
    joins(:state).where(states: { abbrev: state }).find_by(district: district)
  end

  def self.find_by_address(address:, zip_code:, city: nil, state_abbrev: nil,
                           includes: nil)
    results = Integration::Here.geocode_address(address: address,
                                                city:    city,
                                                state:   state_abbrev,
                                                zip:     zip_code)
    if coords = results[:coordinates]
      if district_hash = Integration::MobileCommons.district_from_coords(coords)
        District.includes(includes).find_by_state_and_district(district_hash)
      end
    end
  end

  def fetch_rep
    self.representative = Legislator.fetch_one(district: self)
  end

  def legislators
    join_clause = 'INNER JOIN districts '\
                  'ON (districts.id = legislators.district_id '\
                  'OR districts.state_id = legislators.state_id)'
    Legislator.joins(join_clause).where(districts: { id: id })
  end

  def targeted?
    campaigns.active.any?
  end

  def targeted_by_campaign?(campaign)
    campaigns.include?(campaign)
  end

  def to_s
    state.abbrev + district
  end
end
