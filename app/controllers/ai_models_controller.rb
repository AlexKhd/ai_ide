class AiModelsController < ApplicationController

  def index
    if params[:advanced_only] == "1"
      @ai_models = AiModel.zero_cost.active.supports_tools.supports_reasoning.ordered
    else
      @ai_models = AiModel.ordered
    end
  end

  def sync_models
    service = OpenRouter::AiModelsSyncPreviewService.new
    @diffs = service.call
    @ai_models = AiModel.ordered

    render :index
  end

  def apply_sync
    OpenRouter::AiModelsSyncService.new.call
    redirect_to ai_models_path, notice: "Models synced successfully"
  end
end
