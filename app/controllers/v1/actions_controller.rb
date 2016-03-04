class V1::ActionsController < V1::BaseController

  def index
    @activity = Activity.find_by(template_id: params[:activity_template_id])
    if @activity
      per_page = params[:limit].presence || 30
      @actions = @activity.actions.includes(:person).visible.paginate(
        page: params[:page],
        per_page: per_page,
      ).order('created_at DESC')

      render
    else
      record_not_found(StandardError.new('Record not found.'))
    end
  end

  def create
    # need to handle invalid person
    activity = Activity.find_or_create_by(template_id: activity_param)
    @person = if person_params.any? # temporary fix
                PersonConstructor.new(person_params).build.tap(&:save)
              end

    action_attributes = {person: @person, activity: activity}.merge(action_params)
    action = Action.create(action_attributes)
    if action.invalid?
      error_messages = action.errors.full_messages.join('. ') + '.'
      error_messages += ' Activity not found.' if activity.nil?
      @error = error_messages
    end
    render template: 'v1/people/show'
  end

  def count
    finder = Action
    finder = finder.by_type(params[:activity_type]) if params[:activity_type].present?
    if params[:start_at].present?
      start_at = DateTime.parse(params[:start_at])
      end_at = DateTime.parse(params[:end_at]) if params[:end_at].present?
      finder = finder.by_date(start_at, end_at)
    end
    render json: {count: finder.count}
  end

  private

  def activity_param
    params.require(:template_id)
  end

  def action_params
    params.permit(:utm_source, :utm_medium, :utm_campaign, :source_url,
                  :donation_amount_in_cents, :strike_amount_in_cents,
                  :privacy_status)
  end

  def person_params
    params.require(:person).permit(PersonConstructor.permitted_params)
  end
end
