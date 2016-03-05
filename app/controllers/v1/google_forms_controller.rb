class V1::GoogleFormsController < V1::BaseController

  DEFAULT_PERSON_FIELDS_NOT_ON_GOOGLE = [:remote_fields, :is_volunteer]


  # This provides a generic /v1/google_forms endpoint for processinga and submitting
  # google forms data to Google. A form post action requires the following:
  #  * google_form_metadata - contains form_id and field_mappings
  #      * field_mappings - a hash of {form_field_name: 'google.entry.id'}
  #      * field_id       - a string of the google form's id
  #  * google_form_submission_data - hash of human readable data that will be stored.
  #    Google's servers infer type.
  #    example: {javascript_skill_level: 'advanced', legislator_nominatoin: 'Jack Russel'}
  def create
    person = PersonConstructor.new(person_params).build.tap(&:save) # temporary fix
    if google_form_data_params.values.any?(&:present?) || (person && person.valid?)
      GoogleFormsSubmitJob.perform_later(google_form_metadata_params[:form_id], google_form_mapped_data)
      submitted = true
    else
      submitted = false
    end
    render json: { submitted: submitted }
  end

  private

  def person_params
    params.require(:person).permit(PersonConstructor.permitted_params)
  end
  def person_params
    @person_params ||= fetch_person_params
  end

  def fetch_person_params
    person_params = params.permit(PersonConstructor.permitted_params)
    nested_person_params = params.permit(person: PersonConstructor.permitted_params)[:person]  || {}
    person_params.merge(nested_person_params)
  end

  def google_form_metadata_params
    params.require(:google_form_metadata).permit(:form_id, field_mappings: params[:google_form_metadata][:field_mappings].try(:keys))
  end

  def google_form_data_params
    mergeable_person_params = person_params.except(DEFAULT_PERSON_FIELDS_NOT_ON_GOOGLE)
    google_data_params = params.permit(google_form_submission_data: google_form_metadata_params[:field_mappings].keys)
    mergeable_person_params.merge(google_data_params[:google_form_submission_data] || {}).symbolize_keys
  end

  def google_form_mapped_data
    google_form_data_params.each_with_object({}) do |(internal_key, value), output_hash|
      target_key = google_form_metadata_params[:field_mappings][internal_key]
      output_hash[target_key] = value if target_key.present?
    end
  end

end
