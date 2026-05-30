require "net/http"
require "json"

module OpenRouter
  class ChatCompletion
    API_URL = "https://openrouter.ai/api/v1/chat/completions"

    def initialize(connection:, prompt:)
      @connection = connection
      @prompt = prompt
    end

    def call
      uri = URI(API_URL)

      request = Net::HTTP::Post.new(uri)

      request["Authorization"] = "Bearer #{connection.api_key}"
      request["Content-Type"] = "application/json"
      request["HTTP-Referer"] = "http://localhost:3000"
      request["X-Title"] = "AI IDE"

      request.body = {
        model: connection.ai_model.external_id,
        messages: [
          {
            role: "system",
            content: system_prompt
          },
          {
            role: "user",
            content: prompt
          }
        ]
      }.to_json

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true
      ) do |http|
        http.request(request)
      end

      Rails.logger.info "OPENROUTER STATUS: #{response.code}"
      Rails.logger.info "OPENROUTER BODY: #{response.body}"

      json = JSON.parse(response.body)

      if json["error"]
        raise StandardError, json["error"]["message"]
      end

      content = json.dig("choices", 0, "message", "content")

      if content.blank?
        raise StandardError, "No completion returned"
      end

      content
    end

    private

    attr_reader :connection, :prompt

    def system_prompt
      <<~PROMPT
        You are an expert Ruby on Rails coding assistant.

        Help the user understand, improve, and debug code.

        Be concise and practical.
      PROMPT
    end
  end
end
