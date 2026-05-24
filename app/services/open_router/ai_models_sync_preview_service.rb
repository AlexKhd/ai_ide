require "net/http"
require "json"

module OpenRouter
  class AiModelsSyncPreviewService
    OPENROUTER_URL = "https://openrouter.ai/api/v1/models"

    IMPORTANT_FIELDS = %w[
      name
      context_length
      pricing
      architecture
      supported_parameters
    ]

    def call
      remote_models = fetch_remote_models
      local_models = AiModel.ordered.index_by(&:external_id)

      added = []
      removed = []
      changed = []

      remote_ids = remote_models.map { |m| m["id"] }

      remote_models.each do |remote|
        local = local_models[remote["id"]]

        if local.nil?
          added << remote
          next
        end

        diff = compare(local, remote)

        if diff.present?
          changed << {
            id: remote["id"],
            name: remote["name"],
            changes: diff
          }
        end
      end

      local_models.each do |external_id, local|
        unless remote_ids.include?(external_id)
          removed << local
        end
      end

      {
        added: added,
        removed: removed,
        changed: changed
      }
    end

    private

    def fetch_remote_models
      uri = URI(OPENROUTER_URL)
      response = Net::HTTP.get(uri)

      JSON.parse(response)["data"]
    end

    def compare(local, remote)
      diffs = {}

      if local.name != remote["name"]
        diffs[:name] = [local.name, remote["name"]]
      end

      if local.context_length != remote["context_length"]
        diffs[:context_length] = [
          local.context_length,
          remote["context_length"]
        ]
      end

      prompt_price = remote.dig("pricing", "prompt").to_d

      if local.prompt_price != prompt_price
        diffs[:prompt_price] = [
          local.prompt_price,
          prompt_price
        ]
      end

      completion_price = remote.dig("pricing", "completion").to_d

      if local.completion_price != completion_price
        diffs[:completion_price] = [
          local.completion_price,
          completion_price
        ]
      end

      if local.architecture != remote["architecture"]
        diffs[:architecture] = [
          local.architecture,
          remote["architecture"]
        ]
      end

      diffs
    end
  end
end
