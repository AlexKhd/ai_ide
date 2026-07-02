require "net/http"
require "json"

module OpenRouter
  class ChatCompletion
    API_URL = "https://openrouter.ai/api/v1/chat/completions"

    def initialize(connection:, messages:, tools: [])
      @connection = connection
      @messages = messages
      @tools = tools
    end

    def call
      uri = URI(API_URL)
      request = Net::HTTP::Post.new(uri)

      request["Authorization"] = "Bearer #{connection.api_key}"
      request["Content-Type"] = "application/json"
      request["HTTP-Referer"] = "http://localhost:3000"
      request["X-Title"] = "AI IDE"

      payload = {
        model: connection.ai_model.external_id,
        messages: messages
      }

      # Only inject if your database row says this specific model supports reasoning!
      if connection.ai_model.supports_reasoning?
        payload[:reasoning] = {}
      end

      # Only supply tools if the model configuration supports them
      payload[:tools] = tools if tools.any?

      request.body = payload.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      Rails.logger.info "OPENROUTER STATUS: #{response.code}"

      json = JSON.parse(response.body)
      if json["error"]
        # Log the exact sub-error message (e.g., "invalid field 'tools'") to your console log terminal
        Rails.logger.error "OPENROUTER ERROR DETAILS: #{json['error']}"
        raise StandardError, "Provider returned error: #{json.dig('error', 'message')}"
      end

      choice_message = json.dig("choices", 0, "message")
      raise StandardError, "No completion returned" if choice_message.blank?

      # Deep transform keys to symbols so .dig(:tool_calls) works perfectly!
      symbolized_message = choice_message.deep_symbolize_keys

      {
        content: symbolized_message[:content],
        tool_calls: symbolized_message[:tool_calls]
      }
    end

    private

    attr_reader :connection, :messages, :tools
  end
end
