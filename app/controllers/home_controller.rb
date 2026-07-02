class HomeController < ApplicationController
  def index
    @ai_messages = AiMessage.ordered
  end

  def dashboard
  end
end
