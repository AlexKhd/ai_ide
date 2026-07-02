module Mcp
  class ToolExecutor
    def self.call(tool_name:, input:, session:, message:)
      tool_class = ToolRegistry.fetch(tool_name)

      raise "Unknown tool: #{tool_name}" unless tool_class

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      result = tool_class
        .new(input: input, session: session, message: message)
        .call

      duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round

      result.merge(meta: { duration_ms: duration })
    rescue => e
      {
        ok: false,
        error: e.message,
        data: nil,
        meta: { duration_ms: 0 }
      }
    end
  end
end
