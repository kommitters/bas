# frozen_string_literal: true

module Dispatcher
  module Slack
    module Types
      ##
      # Represents a response received from Slack. It encapsulates essential information about the response,
      # providing a structured way to handle and analyze Slack server responses.
      #
      class Response
        attr_reader :body, :http_code, :message

        def initialize(response)
          @http_code = response.code
          @message = response.message
          @body = response.body
        end
      end
    end
  end
end
