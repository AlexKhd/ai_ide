class AiController < ApplicationController
  protect_from_forgery with: :null_session

  def code_suggest
    connection = AiConnection.active_connection

    unless connection
      render json: {
        suggestion: "No active AI connection configured."
      }, status: :unprocessable_entity

      return
    end

    suggestion = OpenRouter::ChatCompletion.new(
      connection: connection,
      prompt: params[:code]
    ).call

    render json: { suggestion: suggestion }
  rescue => e
    render json: {
      suggestion: "Error: #{e.message}"
    }, status: :internal_server_error
  end
end
