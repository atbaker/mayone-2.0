class V1::DonationPagesController < ApplicationController
  def index
    @donation_pages = DonationPage.by_funds_raised.limit(limit)

    render :index
  end

  def show
    @donation_page = find_donation_page

    render :show
  end

  def create
    person = find_or_initialize_person
    donation_page = person.donation_pages.new(donation_page_params)

    if person.save && donation_page.save
      donation_page.reload
      render json: { uuid: donation_page.uuid }, status: :created
    else
      render json: { error: merge_errors(person, donation_page) },
        status: :unprocessable_entity
    end
  end

  def update
    donation_page = find_donation_page

    if donation_page.authorize_and_update(donation_page_params)
      head :no_content
    else
      render json: { errors: @donation_page.errors },
        status: :unprocessable_entity
    end
  end

  def destroy
    donation_page = find_donation_page

    donation_page.destroy

    head :no_content
  end

  def validate
    person = find_or_initialize_person
    donation_page = person.donation_pages.new(donation_page_params)

    valid = person.valid? # this will also validate person.donation_pages
    errors = person.errors.to_hash.merge(donation_page.errors.to_hash)
    render json: { valid: valid, errors: errors }
  end

  private

  def merge_errors(*records)
    errors = {}
    records.each do |record|
      errors.merge!(record.errors.to_hash)
    end
    errors
  end

  def find_donation_page
    DonationPage.find_by!(slug: params[:slug])
  end

  def donation_page_params
    params.require(:donation_page).permit(:title, :slug, :visible_user_name,
      :photo_url, :intro_text, :goal_in_cents, :access_token)
  end

  def person_params
    params.require(:person).permit(PersonConstructor.permitted_params)
  end

  def find_or_initialize_person
    person = Person.find_or_initialize_by(email: person_params[:email])
    person.assign_attributes(person_params)
    person
  end

  def limit
    params[:limit] || 10
  end
end
