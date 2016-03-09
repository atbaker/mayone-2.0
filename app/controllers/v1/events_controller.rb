class V1::EventsController < V1::BaseController

  def index
    @events = Event.upcoming
    render
  end

  def create_rsvp
    person = create_person_and_action(default_template_id: Activity::DEFAULT_TEMPLATE_IDS[:rsvp])

    response, status = rescue_error_messages do |variable|
      Integration::NationBuilder.create_person_and_rsvp(event_id: params[:event_id], person_attributes: person.attributes.symbolize_keys)
    end
    render json: response, status: status
  end

end
