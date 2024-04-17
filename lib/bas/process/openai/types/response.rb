# frozen_string_literal: true

module Process
  module OpenAI
    module Types
      ##
      # Represents a response received from the OpenAI chat completion service API. It encapsulates
      # essential information about the response, providing a structured way to handle and analyze
      # its responses.
      class Response
        attr_reader :status_code, :message, :choices

        def initialize(response)
          if response["error"]
            @status_code = response.code
            @message = response["error"]
            @choices = []
          else
            @status_code = 200
            @message = "success"
            puts response
            @choices = response["choices"]
          end
        end
      end
    end
  end
end
