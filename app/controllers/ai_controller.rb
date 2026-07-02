class AiController < ApplicationController
  protect_from_forgery with: :null_session

  def code_suggestsse
    connection = current_connection
    # respond_to do |format|
    #  format.html { redirect_to root_path } # Fallback
    # end

    # SSE Streaming
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Access-Control-Allow-Origin"] = "*"

    # Simulate streaming chunks (replace with real LLM)
    # chunks = [
    #  "Your Ruby code is almost correct! ",
    #  "Here's the improved version:\n\n",
    #  "```ruby\n# Write your Ruby code here\nputs 'Hello AI IDE!'\n```\n\n",
    #  "What was changed:\n\n",
    #  "| Issue | Before | After |\n|-------|--------|-------|\n",
    #  "| Comment syntax | // Write your Ruby code here | # Write your Ruby code here |\n\n",
    #  "Why: Ruby uses the # symbol for single-line comments, not // (which is C++)\n",
    #  "[DONE]"
    # ]

    open_router_service = OpenRouter::ChatCompletionStream.new(
      connection: connection,
      prompt: params[:code]
    )

    render plain: "" # Start stream
    open_router_service.each_chunk do |chunk|
      response.stream.write "data: #{chunk.to_json}\n\n"
      sleep 0.1 # Simulate LLM delay
    end
    done_message = "[DONE]".to_json
    response.stream.write "data: #{done_message}\n\n"
    response.stream.close
  end

  def code_suggest
    if params[:code] == 'test'
      render json: { suggestion: "User sent test message, nothing to be done. Skipping..." } and return
    end

    connection = current_connection
    unless connection
      render json: { suggestion: "No active AI connection configured." }, status: :unprocessable_entity
      return
    end

    ai_session = current_user.ai_sessions.find_by(active: true) || current_user.ai_sessions.create!(ai_model: connection.ai_model, ai_connection: connection)

    runner = Mcp::AgentRunner.new(ai_session)
    final_suggestion = runner.process_user_message!(params[:code].to_s)

    render json: { suggestion: final_suggestion }
  rescue => e
    Rails.logger.error("Agent Loop Failed: #{e.message}\n#{e.backtrace.join("\n")}")
    render json: { suggestion: "Error: #{e.message}" }, status: :internal_server_error
  end
end
