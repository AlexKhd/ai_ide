module Mcp
  class AgentRunner
    def initialize(ai_session)
      @session = ai_session
      @connection = ai_session.ai_connection
    end

    def process_user_message!(user_prompt)
      # Save the user message to DB
      @session.ai_messages.create!(role: "user", content: user_prompt)

      # Start the execution cycle and return its final value
      execute_agent_loop(0)
    end

    private

    def execute_agent_loop(depth = 0)
      # Safeguard against run-away infinite loops
      if depth > 5
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

        # Re-enter loop: Pass file contents/results back down to the model
        execute_agent_loop(depth + 1)
      else
        # Final response text achieved: Save and return it
        @session.ai_messages.create!(role: "assistant", content: response[:content])
        response[:content]
      end
    end

    def build_message_history
      history = []
      history << { role: "system", content: @session.system_prompt } if @session.system_prompt.present?

      @session.ai_messages.order(:created_at).each do |msg|
        payload = { role: msg.role }

        # Cohere strict rule: completely omit content key if it is nil or empty string
        payload[:content] = msg.content if msg.content.present?
        payload[:name] = msg.name if msg.name.present?
        payload[:tool_call_id] = msg.tool_call_id if msg.tool_call_id.present?

        if msg.role == "assistant" && msg.metadata&.dig("tool_calls").present?
          payload[:tool_calls] = msg.metadata["tool_calls"]
        end

        history << payload
      end
      history
    end

    def handle_tool_calls(tool_calls, intermediate_content)
      assistant_msg = @session.ai_messages.create!(
        role: "assistant",
        content: intermediate_content,
        metadata: { "tool_calls" => tool_calls }
      )

      tool_calls.each do |call_data|
        # Ensure we can read string keys coming back from OpenRouter JSON responses
        tool_name = call_data.dig(:function, :name) || call_data.dig("function", "name")

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

        tool_call_id = call_data[:id] || call_data["id"]
        raw_args = call_data.dig(:function, :arguments) || call_data.dig("function", "arguments")
        parsed_args = raw_args.is_a?(String) ? JSON.parse(raw_args) : raw_args

        mcp_tool = ::McpTool.find_by(name: tool_name)
        next unless mcp_tool

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
