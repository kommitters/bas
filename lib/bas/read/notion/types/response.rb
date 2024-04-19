# frozen_string_literal: true

module Read
  module Notion
    module Types
      ##
      # Represents a response received from the Notion API. It encapsulates essential information about the response,
      # providing a structured way to handle and analyze its responses.
      class Response
        attr_reader :status_code, :message, :results

        def initialize(response)
          if response["results"].nil?
            @status_code = response["status"]
            @message = response["message"]
            @results = []
          else
            @status_code = 200
            @message = "success"
            @results = response["results"]
          end
        end
      end
    end
  end
end
