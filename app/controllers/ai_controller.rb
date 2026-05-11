class AiController < ApplicationController
  protect_from_forgery with: :null_session # for JSON POSTs from JS

  def code_suggest
    code = params[:code] || ""

    # For now, just echo back code
    suggestion = "You typed:\n#{code}"

    render json: { suggestion: suggestion }
  end
end
