class AiMessagesController < ApplicationController

  def index
    @ai_messages = AiMessage.ordered
  end

  def destroy
    @ai_message = AiMessage.find(params.expect(:id))
    @ai_message.destroy!

    respond_to do |format|
      format.html { redirect_to home_index_path, notice: "Message was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def destroy_all
    AiMessage.in_batches(of: 1000).destroy_all

    respond_to do |format|
      format.html { redirect_to ai_messages_path, status: :see_other, notice: "All AI messages deleted." }
      format.turbo_stream { flash.now[:notice] = "All AI messages deleted." }
    end
  end
end
