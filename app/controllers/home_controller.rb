class HomeController < ApplicationController
  def index
    @current_connection = AiConnection.active_connection
  end
end
