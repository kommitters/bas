# frozen_string_literal: true

module Dispatcher
  module Discord
    module Types
      ##
      # Represents a response received from Discord. It encapsulates essential information about the response,
      # providing a structured way to handle and analyze Discord server responses.
      #
      class Response
        attr_reader :code, :http_code, :message, :response

        def initialize(response)
          @http_code = response.code
          @code = response["code"]
          @message = response.message
          @response = response.response
        end
      end
    end
  end
end
