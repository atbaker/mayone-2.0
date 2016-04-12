json.(action, :id, :created_at, :strike_amount_in_cents)
json.first_name action.person.first_name
json.last_initial action.person.last_initial
json.location action.person.guaranteed_location, :city, :state_abbrev
