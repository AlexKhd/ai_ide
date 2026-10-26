class VserversController < ApplicationController
  before_action :set_vserver, only: %i[ status firewall configure_firewall edit update destroy ]

  # GET /vservers or /vservers.json
  def index
    @vservers = Vserver.all
  end

  def status
    @firewall_result = VserverFirewallService.new(@vserver).status
  end

  def firewall
    @firewall_result = VserverFirewallService.new(@vserver).status
  end

  def configure_firewall
    # Add authentication and authorization checks here.

    result = VserverFirewallService.new(@vserver).apply_baseline

    if result.success?
      redirect_to firewall_vserver_path(@vserver),
                  notice: "Firewall configuration applied."
    else
      redirect_to firewall_vserver_path(@vserver),
                  alert: result.message
    end
  end

  def install_firewall_helper
    @vserver = Vserver.find(params[:id])

    result = VserverFirewallService.new(@vserver).install_helper

    redirect_to status_vserver_path(@vserver), (result.success? ? :notice : :alert) => result.message
  end

  def apply_firewall_baseline
    @vserver = Vserver.find(params[:id])

    # Add authorization checks before enabling the firewall.

    result = VserverFirewallService.new(@vserver).apply_baseline

    redirect_to status_vserver_path(@vserver), (result.success? ? :notice : :alert) => result.message
  end

  def check_status
    @vserver = Vserver.find(params[:id])

    if @vserver.update(checking: true)
      CheckVserverHealthJob.perform_later(@vserver)
    end

    redirect_to vservers_path, notice: "Health check started."
  rescue StandardError => e
    @vserver&.update(checking: false)
    raise e
  end

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
      params.expect(vserver: [ :name, :host, :healthcheck, :port, :username, :local_path, :enabled, :ssh_port ])
    end
end
