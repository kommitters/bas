# frozen_string_literal: true

module Fetcher
  module Notion
    module Types
      ##
      # Represents a response received from the Notion API. It encapsulates essential information about the response,
      # providing a structured way to handle and analyze it's responses.
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
