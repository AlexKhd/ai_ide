require 'net/http'
require 'json'

module OpenRouter
  class ChatCompletionStream
    attr_reader :connection
    API_URL = "https://openrouter.ai/api/v1/chat/completions"
    connection = AiConnection.active_connection

    def initialize(connection:, prompt:)
      @connection ||= connection
      @prompt = prompt
    end

    def each_chunk
      uri = URI(API_URL)
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{connection.api_key}"
      req["Content-Type"] = "application/json"

      req.body = {
        model: connection.ai_model.external_id,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: @prompt }
        ],
        stream: true
      }.to_json

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req) do |res|
          res.read_body do |chunk|
            # SSE wants line by line data, OpenRouter sends JSON per line
            chunk.each_line do |line|
              next if line.strip.empty? || line.start_with?(":") # skip heartbeat
              if line.start_with?("data: ")
                data_str = line[6..].strip
                # Skip the [DONE] message that signals end of stream
                next if data_str == "[DONE]"

                data = JSON.parse(data_str)
                content = data.dig("choices", 0, "delta", "content")
                yield(content) if content
              end
            end
          end
        end
      end
    end

    private

    def system_prompt
      "You are an expert Ruby on Rails coding assistant. Help the user improve their code."
    end
  end
end
