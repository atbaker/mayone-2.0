class V1::BaseController < ApplicationController

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :missing_parameter

  protected

  # OAuth2 errors are no longer relevant. Need to research NB errors
  def rescue_error_messages
    begin
      response = yield
      [response, 200]
    rescue ArgumentError, OAuth2::Error => e
      [{error: e.message}, 422]
    end
  end

  def missing_parameter(error)
    render json: { error: "#{error.param} is required" }, status: 422
  end

  def record_not_found(error)
    render json: {error: error.message}, status: :not_found
  end

  def create_person_and_action(default_template_id: nil)
    person_params = params.require(:person).permit(PersonConstructor.permitted_params)
    person = PersonConstructor.new(person_params).build.tap(&:save) # temporary fix

    action_params = params.permit(:template_id, :utm_source, :utm_medium, :utm_campaign, :source_url)
    action_params[:template_id] ||= default_template_id

    person.create_action(action_params.symbolize_keys)

    person
  end

end
