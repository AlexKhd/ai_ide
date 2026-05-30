class AiConnectionsController < ApplicationController
  before_action :set_ai_connection, only: %i[ show edit update destroy ]

  # GET /ai_connections or /ai_connections.json
  def index
    @ai_connections = AiConnection.all
    @models = AiModel.ordered
  end

  def sync_models
    service = OpenRouter::AiModelsSyncPreviewService.new
    @diffs = service.call

    @ai_connections = AiConnection.all
    @models = AiModel.all

    render :index
  end

  def apply_sync
    OpenRouter::AiModelsSyncService.new.call
    redirect_to ai_connections_path, notice: "Models synced successfully"
  end

  # GET /ai_connections/1 or /ai_connections/1.json
  def show
    @ai_models = AiModel.zero_cost.ordered
    if params[:provider].present?
      @ai_models = @ai_models.where(provider: params[:provider])
    end
  end

  # GET /ai_connections/new
  def new
    @ai_connection = AiConnection.new
  end

  # GET /ai_connections/1/edit
  def edit
  end

  # POST /ai_connections or /ai_connections.json
  def create
    @ai_connection = AiConnection.new(ai_connection_params)

    respond_to do |format|
      if @ai_connection.save
        format.html { redirect_to ai_connections_path, notice: "Ai connection was successfully created." }
        format.json { render :show, status: :created, location: @ai_connection }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ai_connection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ai_connections/1 or /ai_connections/1.json
  def update
    @ai_connection.model_id = params[:model][:external_id]
    respond_to do |format|
      if @ai_connection.update(ai_connection_params)
        format.html { redirect_to ai_connections_path, notice: "Ai connection was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @ai_connection }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ai_connection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ai_connections/1 or /ai_connections/1.json
  def destroy
    @ai_connection.destroy!

    respond_to do |format|
      format.html { redirect_to ai_connections_path, notice: "Ai connection was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ai_connection
      @ai_connection = AiConnection.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def ai_connection_params
      params.expect(ai_connection: [ :name, :provider, :api_key, :model, :active ])
    end
end
