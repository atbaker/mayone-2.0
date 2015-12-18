# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151218172510) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.integer  "person_id",                null: false
    t.integer  "activity_id",              null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "utm_source"
    t.string   "utm_medium"
    t.string   "utm_campaign"
    t.string   "source_url"
    t.integer  "donation_amount_in_cents"
  end

  add_index "actions", ["activity_id"], name: "index_actions_on_activity_id", using: :btree
  add_index "actions", ["donation_amount_in_cents"], name: "index_actions_on_donation_amount_in_cents", using: :btree
  add_index "actions", ["person_id", "activity_id"], name: "index_actions_on_person_id_and_activity_id", using: :btree
  add_index "actions", ["person_id"], name: "index_actions_on_person_id", using: :btree

  create_table "activities", force: :cascade do |t|
    t.string   "name"
    t.string   "template_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "sort_order"
    t.string   "activity_type"
  end

  add_index "activities", ["activity_type"], name: "index_activities_on_activity_type", using: :btree
  add_index "activities", ["template_id"], name: "index_activities_on_template_id", unique: true, using: :btree

  create_table "bills", force: :cascade do |t|
    t.string   "bill_id"
    t.string   "chamber"
    t.string   "short_title"
    t.string   "summary_short"
    t.integer  "congressional_session"
    t.string   "opencongress_url"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.string   "official_title"
  end

  add_index "bills", ["bill_id"], name: "index_bills_on_bill_id", unique: true, using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "ended_at"
    t.boolean  "is_default"
  end

  create_table "districts", force: :cascade do |t|
    t.string   "district"
    t.integer  "state_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "districts", ["state_id"], name: "index_districts_on_state_id", using: :btree

  create_table "districts_zip_codes", id: false, force: :cascade do |t|
    t.integer "district_id", null: false
    t.integer "zip_code_id", null: false
  end

  add_index "districts_zip_codes", ["district_id", "zip_code_id"], name: "index_districts_zip_codes_on_district_id_and_zip_code_id", using: :btree
  add_index "districts_zip_codes", ["zip_code_id", "district_id"], name: "index_districts_zip_codes_on_zip_code_id_and_district_id", unique: true, using: :btree

  create_table "events", force: :cascade do |t|
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer  "remote_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "events", ["remote_id"], name: "index_events_on_remote_id", unique: true, using: :btree

  create_table "ivr_calls", force: :cascade do |t|
    t.string   "remote_id"
    t.integer  "person_id"
    t.string   "status"
    t.integer  "duration"
    t.datetime "ended_at"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "call_type"
    t.string   "remote_origin_phone"
    t.string   "campaign_ref"
    t.integer  "campaign_id"
  end

  add_index "ivr_calls", ["person_id"], name: "index_ivr_calls_on_person_id", using: :btree

  create_table "ivr_connections", force: :cascade do |t|
    t.string   "remote_id"
    t.integer  "call_id"
    t.integer  "legislator_id"
    t.string   "status_from_user"
    t.string   "status"
    t.integer  "duration"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "ivr_connections", ["call_id"], name: "index_ivr_connections_on_call_id", using: :btree
  add_index "ivr_connections", ["legislator_id"], name: "index_ivr_connections_on_legislator_id", using: :btree

  create_table "ivr_recordings", force: :cascade do |t|
    t.integer  "duration"
    t.string   "recording_url"
    t.string   "state"
    t.integer  "call_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "ivr_recordings", ["call_id"], name: "index_ivr_recordings_on_call_id", using: :btree

  create_table "legislators", force: :cascade do |t|
    t.string   "bioguide_id",         null: false
    t.date     "birthday"
    t.string   "chamber"
    t.integer  "district_id"
    t.string   "facebook_id"
    t.string   "first_name"
    t.string   "gender"
    t.boolean  "in_office"
    t.string   "last_name"
    t.string   "middle_name"
    t.string   "name_suffix"
    t.string   "nickname"
    t.string   "office"
    t.string   "party"
    t.string   "phone"
    t.integer  "senate_class"
    t.integer  "state_id"
    t.string   "state_rank"
    t.date     "term_end"
    t.date     "term_start"
    t.string   "title"
    t.string   "verified_first_name"
    t.string   "verified_last_name"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "twitter_id"
  end

  add_index "legislators", ["bioguide_id"], name: "index_legislators_on_bioguide_id", unique: true, using: :btree
  add_index "legislators", ["district_id"], name: "index_legislators_on_district_id", using: :btree
  add_index "legislators", ["state_id"], name: "index_legislators_on_state_id", using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "location_type"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "city"
    t.integer  "state_id"
    t.string   "zip_code"
    t.integer  "person_id"
    t.integer  "district_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "locations", ["district_id"], name: "index_locations_on_district_id", using: :btree
  add_index "locations", ["person_id"], name: "index_locations_on_person_id", using: :btree
  add_index "locations", ["state_id"], name: "index_locations_on_state_id", using: :btree

  create_table "people", force: :cascade do |t|
    t.string   "email"
    t.string   "phone"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "first_name"
    t.string   "last_name"
    t.string   "uuid"
    t.boolean  "is_volunteer"
  end

  add_index "people", ["email"], name: "index_people_on_email", unique: true, using: :btree
  add_index "people", ["uuid"], name: "index_people_on_uuid", unique: true, using: :btree

  create_table "sponsorships", force: :cascade do |t|
    t.integer  "bill_id",            null: false
    t.integer  "legislator_id",      null: false
    t.datetime "pledged_support_at"
    t.datetime "cosponsored_at"
    t.datetime "introduced_at"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "sponsorships", ["bill_id"], name: "index_sponsorships_on_bill_id", using: :btree
  add_index "sponsorships", ["legislator_id"], name: "index_sponsorships_on_legislator_id", using: :btree

  create_table "states", force: :cascade do |t|
    t.string   "name"
    t.string   "abbrev"
    t.boolean  "single_district"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "states", ["abbrev"], name: "index_states_on_abbrev", unique: true, using: :btree
  add_index "states", ["name"], name: "index_states_on_name", unique: true, using: :btree

  create_table "targets", force: :cascade do |t|
    t.integer  "campaign_id"
    t.integer  "legislator_id"
    t.integer  "priority"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "targets", ["campaign_id"], name: "index_targets_on_campaign_id", using: :btree
  add_index "targets", ["legislator_id", "campaign_id"], name: "index_targets_on_legislator_id_and_campaign_id", unique: true, using: :btree
  add_index "targets", ["legislator_id"], name: "index_targets_on_legislator_id", using: :btree

  create_table "zip_codes", force: :cascade do |t|
    t.string   "zip_code"
    t.string   "city"
    t.integer  "state_id"
    t.integer  "district_count"
    t.boolean  "on_house_gov"
    t.datetime "last_checked"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "zip_codes", ["state_id"], name: "index_zip_codes_on_state_id", using: :btree
  add_index "zip_codes", ["zip_code"], name: "index_zip_codes_on_zip_code", unique: true, using: :btree

  add_foreign_key "actions", "activities"
  add_foreign_key "actions", "people"
  add_foreign_key "districts", "states"
  add_foreign_key "ivr_calls", "people"
  add_foreign_key "ivr_connections", "ivr_calls", column: "call_id"
  add_foreign_key "ivr_connections", "legislators"
  add_foreign_key "legislators", "districts"
  add_foreign_key "legislators", "states"
  add_foreign_key "locations", "districts"
  add_foreign_key "locations", "people"
  add_foreign_key "locations", "states"
  add_foreign_key "sponsorships", "bills"
  add_foreign_key "sponsorships", "legislators"
  add_foreign_key "targets", "campaigns"
  add_foreign_key "targets", "legislators"
  add_foreign_key "zip_codes", "states"
end
