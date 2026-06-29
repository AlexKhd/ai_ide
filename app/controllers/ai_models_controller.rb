class AiModelsController < ApplicationController

  def index
    @models = AiModel.ordered
    @ai_connections = AiConnection.all
  end

end
