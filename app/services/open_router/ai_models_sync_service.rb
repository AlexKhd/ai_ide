require "net/http"
require "json"

module OpenRouter
  class AiModelsSyncService
    OPENROUTER_URL = "https://openrouter.ai/api/v1/models"

    def call
      remote_models = fetch_remote_models

      existing = AiModel.all.index_by(&:external_id)

      remote_ids = []

      remote_models.each do |remote|
        external_id = remote["id"]

        remote_ids << external_id

        attrs = build_attributes(remote)

        model = existing[external_id]

        if model
          model.update!(attrs.merge(active: true))
        else
          AiModel.create!(attrs.merge(active: true))
        end
      end

      AiModel.where.not(external_id: remote_ids)
             .update_all(active: false)
    end

    private

    def fetch_remote_models
      uri = URI(OPENROUTER_URL)
      response = Net::HTTP.get(uri)

      JSON.parse(response)["data"]
    end

    def build_attributes(remote)
      {
        ai_connection_id: AiConnection.active.id, # find_connection_id(remote),

        external_id: remote["id"],
        name: remote["name"],
        provider: provider(remote),

        context_length: remote["context_length"],

        input_modalities: remote.dig("architecture", "input_modalities"),
        output_modalities: remote.dig("architecture", "output_modalities"),

        supports_tools: supports_tools?(remote),
        supports_reasoning: supports_reasoning?(remote),

        prompt_price: remote.dig("pricing", "prompt"),
        completion_price: remote.dig("pricing", "completion"),

        architecture: remote["architecture"],
        raw: remote
      }
    end

    def provider(remote)
      remote["id"].split("/").first
    end

    def supports_tools?(remote)
      remote["supported_parameters"]&.include?("tools")
    end

    def supports_reasoning?(remote)
      remote["supported_parameters"]&.include?("reasoning")
    end

    def find_connection_id(remote)
      provider_name = provider(remote)
      AiConnection.find_by!(provider: provider_name).id
    end
  end
end
