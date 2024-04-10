# frozen_string_literal: true

module Read
  module Github
    module Types
      ##
      # Represents a response received from the Octokit Github client. It encapsulates essential
      # information about the response, providing a structured way to handle and analyze
      # it's responses.
      class Response
        attr_reader :status_code, :message, :results

        def initialize(response)
          if response.empty?
            @status_code = 404
            @message = "no result were found"
            @results = []
          else
            @status_code = 200
            @message = "success"
            @results = response
          end
        end
      end
    end
  end
end
