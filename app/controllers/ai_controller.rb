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
    connection = current_connection

    unless connection
      render json: {
        suggestion: "No active AI connection configured."
      }, status: :unprocessable_entity

      return
    end

    suggestion = OpenRouter::ChatCompletion.new(
      connection: connection,
      prompt: params[:code]
    ).call

    render json: { suggestion: suggestion }
  rescue => e
    render json: {
      suggestion: "Error: #{e.message}"
    }, status: :internal_server_error
  end
end
