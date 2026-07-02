module Mcp
  module Tools
    class BaseTool
      attr_reader :input, :session, :message

      def initialize(input:, session:, message:)
        @input = input
        @session = session
        @message = message
      end

      def call
        raise NotImplementedError, "Tool must implement #call"
      end

      def success(data = {})
        {
          ok: true,
          data: data,
          error: nil
        }
      end

      def failure(error)
        {
          ok: false,
          data: nil,
          error: error.to_s
        }
      end
    end
  end
end
