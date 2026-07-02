class AiMessagesController < ApplicationController

  def destroy
    @ai_message = AiMessage.find(params.expect(:id))
    @ai_message.destroy!

    respond_to do |format|
      format.html { redirect_to home_index_path, notice: "Message was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end
end
