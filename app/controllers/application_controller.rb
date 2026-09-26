class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user
  helper_method :current_connection
  helper_method :current_ai_session
  helper_method :today_request_count

  def today_request_count
    @today_request_count ||= begin
      user_messages_count = AiMessage.where(created_at: Time.current.all_day, role: 'user').count
      tool_call_count = AiToolCall.where(created_at: Time.current.all_day).count
      user_messages_count + tool_call_count
    end
  end

  def current_user
    Current.user
  end

  def current_connection
    @current_connection ||= AiConnection.active_connection
  end

  def current_ai_session
    @current_ai_session ||= get_current_ai_session
  end

  private

    def get_current_ai_session
      AiSession.first_or_create!(
        user_id: current_user.id,
        ai_connection_id: current_connection.id,
        ai_model_id: current_connection.ai_model.id
      )
    end
end
