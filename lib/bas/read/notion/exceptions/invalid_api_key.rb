# frozen_string_literal: true

module Exceptions
  module Notion
    ##
    # Provides a domain-specific representation for errors that occurs when an invalid API key is provided
    # for a Notion-related operation.
    #
    class InvalidApiKey < StandardError
      def initialize(message = "The provided API token is invalid.")
        super(message)
      end
    end
  end
end
