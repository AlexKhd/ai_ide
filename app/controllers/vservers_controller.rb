class VserversController < ApplicationController
  before_action :set_vserver, only: %i[ status edit update destroy ]

  # GET /vservers or /vservers.json
  def index
    @vservers = Vserver.all
  end

  def status
  end

  def check_status
    @vserver = Vserver.find(params[:id])

    CheckVserverHealthJob.perform_later(@vserver)

    redirect_to vservers_path, notice: "Health check started."
  end

  # GET /vservers/new
  def new
    @vserver = Vserver.new
  end

  # GET /vservers/1/edit
  def edit
  end

  # POST /vservers or /vservers.json
  def create
    @vserver = Vserver.new(vserver_params)

    respond_to do |format|
      if @vserver.save
        format.html { redirect_to vservers_path, notice: "VPS record was successfully created." }
        format.json { render :index, status: :created, location: @vserver }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @vserver.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /vservers/1 or /vservers/1.json
  def update
    respond_to do |format|
      if @vserver.update(vserver_params)
        format.html { redirect_to vservers_path, notice: "VPS record was successfully updated.", status: :see_other }
        format.json { render :index, status: :ok, location: @vserver }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @vserver.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vservers/1 or /vservers/1.json
  def destroy
    @vserver.destroy!

    respond_to do |format|
      format.html { redirect_to vservers_path, notice: "VPS record was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vserver
      @vserver = Vserver.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def vserver_params
      params.expect(vserver: [ :name, :host, :healthcheck, :port, :username, :local_path, :enabled ])
    end
end
