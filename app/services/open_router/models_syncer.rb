require "net/http"
require "json"

module OpenRouter
  class ModelsSyncer
    API_URL = "https://openrouter.ai/api/v1/models"

    def initialize(connection)
      @connection = connection
    end

    def call
      models.each do |model_data|
        upsert_model(model_data)
      end
    end

    private

    attr_reader :connection

    def models
      uri = URI(API_URL)

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{connection.api_key}"
      request["Content-Type"] = "application/json"

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true
      ) do |http|
        http.request(request)
      end

      json = JSON.parse(response.body)

      json["data"] || []
    end

    def upsert_model(data)
      model = connection.ai_models.find_or_initialize_by(
        external_id: data["id"]
      )

      model.update!(
        name: data["name"],
        provider: extract_provider(data["id"]),
        context_length: data["context_length"],

        input_modalities: data.dig("architecture", "input_modalities"),
        output_modalities: data.dig("architecture", "output_modalities"),

        supports_tools: supports?(data, "tools"),
        supports_reasoning: supports?(data, "reasoning"),

        prompt_price: data.dig("pricing", "prompt"),
        completion_price: data.dig("pricing", "completion"),

        architecture: data["architecture"],
        raw: data
      )
    end

    def extract_provider(id)
      id.split("/").first
    end

    def supports?(data, feature)
      Array(data["supported_parameters"]).include?(feature)
    end
  end
end
