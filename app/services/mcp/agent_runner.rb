module Mcp
  class AgentRunner
    include FileHelper

    MAX_DEPTH = 15
    REQUEST_DELAY_SECONDS = 1.0

    def initialize(ai_session, max_depth: MAX_DEPTH)
      @session = ai_session
      @connection = ai_session.ai_connection
      @max_depth = max_depth
      file_append('messages', "-------- Starting messaging, session id: #{@session.id} --------", 2.megabytes)
    end

    def process_user_message!(user_prompt)
      # Save the user message to DB
      file_append('messages', "processing message from user: #{user_prompt}", 2.megabytes)
      @session.ai_messages.create!(role: "user", content: user_prompt)

      # Start the execution cycle and return its final value
      execute_agent_loop(0)
    end

    private

    def execute_agent_loop(depth = 0)
      # Safeguard against run-away infinite loops
      if depth > @max_depth
        file_append('messages', "Error: Maximum agent tool execution depth reached without completion.", 2.megabytes)
        return "Error: Maximum agent tool execution depth reached without completion."
      end

      # Formats database history into standard OpenRouter messages array
      messages_payload = build_message_history

      # Call OpenRouter
      response = OpenRouter::ChatCompletion.new(
        connection: @connection,
        messages: messages_payload,
        tools: Mcp::ToolRegistry.definitions_for_llm
      ).call

      # Check if the LLM wants to read a file or perform an action
      if response[:tool_calls].present?
        handle_tool_calls(response[:tool_calls], response[:content])

        # Pace requests to prevent network/socket congestion and rate-limiting
        sleep(REQUEST_DELAY_SECONDS) if REQUEST_DELAY_SECONDS.to_f > 0

        # Re-enter loop: Pass file contents/results back down to the model
        execute_agent_loop(depth + 1)
      else
        # Final response text achieved: Save and return it
        file_append('messages', "assistant response: #{response[:content]}", 2.megabytes)
        @session.ai_messages.create!(role: "assistant", content: response[:content])
        response[:content]
      end
    end

    def build_message_history
      history = []
      history << { role: "system", content: @session.system_prompt } if @session.system_prompt.present?

      # Collect all tool_call_id strings that have received responses in session history
      completed_tool_call_ids = @session.ai_messages.where(role: "tool").pluck(:tool_call_id).compact.map(&:to_s).to_set

      @session.ai_messages.order(:created_at).each do |msg|
        payload = { role: msg.role }

        # Cohere / OpenRouter strict rule: completely omit content key if it is nil or empty string
        payload[:content] = msg.content if msg.content.present?
        payload[:name] = msg.name if msg.name.present?
        payload[:tool_call_id] = msg.tool_call_id if msg.tool_call_id.present?

        if msg.role == "assistant" && msg.metadata&.dig("tool_calls").present?
          # Filter tool_calls to only include ones that have a matching tool response in history
          valid_tool_calls = msg.metadata["tool_calls"].select do |tc|
            tc_id = tc[:id] || tc["id"]
            completed_tool_call_ids.include?(tc_id.to_s)
          end

          payload[:tool_calls] = valid_tool_calls if valid_tool_calls.any?
        end

        # Skip assistant messages if they have no content AND no valid completed tool_calls
        next if msg.role == "assistant" && payload[:content].blank? && payload[:tool_calls].blank?

        history << payload
      end
      history
    end

    def handle_tool_calls(tool_calls, intermediate_content)
      file_append('messages', "iterating: #{tool_calls} // #{intermediate_content}", 2.megabytes)
      assistant_msg = @session.ai_messages.create!(
        role: "assistant",
        content: intermediate_content,
        metadata: { "tool_calls" => tool_calls }
      )

      tool_calls.each do |call_data|
        # Ensure we can read string keys coming back from OpenRouter JSON responses
        tool_name = call_data.dig(:function, :name) || call_data.dig("function", "name")
        tool_call_id = call_data[:id] || call_data["id"]
        raw_args = call_data.dig(:function, :arguments) || call_data.dig("function", "arguments")
        parsed_args = if raw_args.is_a?(String)
          begin
            JSON.parse(raw_args)
          rescue JSON::ParserError
            raw_args
          end
        else
          raw_args
        end

        mcp_tool = ::McpTool.find_by(name: tool_name)
        next unless mcp_tool

        if tool_name == "file_write"
          # Create the tracking record as "pending"
          ::AiToolCall.create!(
            ai_message: assistant_msg,
            mcp_tool: mcp_tool,
            status: "pending_approval", # 👈 Locks execution down!
            input: parsed_args
          )

          # Stop the agent loop right here! Return a special instruction to the user UI
          return "PAUSED_FOR_APPROVAL"
        end

        db_tool_call = ::AiToolCall.create!(
          ai_message: assistant_msg,
          mcp_tool: mcp_tool,
          status: "running",
          input: parsed_args
        )

        execution_result = Mcp::ToolExecutor.call(
          tool_name: tool_name,
          input: parsed_args,
          session: @session,
          message: assistant_msg
        )

        if execution_result[:ok]
          db_tool_call.update!(status: "success", output: execution_result[:data], duration_ms: execution_result.dig(:meta, :duration_ms))
          content_output = execution_result[:data].to_json
        else
          db_tool_call.update!(status: "failed", error: execution_result[:error], duration_ms: execution_result.dig(:meta, :duration_ms))
          content_output = { error: execution_result[:error] }.to_json
        end

        # CRUCIAL: Write the 'tool' role record back to history with the exact matching tool_call_id string
        file_append('messages', "Tool result: #{content_output}", 2.megabytes)
        @session.ai_messages.create!(
          role: "tool",
          name: tool_name,
          tool_call_id: tool_call_id, # This MUST match what Cohere generated!
          content: content_output
        )
      end
    end
  end
end
