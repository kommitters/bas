# frozen_string_literal: true

module Exceptions
  module Notion
    ##
    # Provides a domain-specific representation for errors that occurs when an invalid database id is provided
    # for a Notion-related operation.
    #
    class InvalidDatabaseId < StandardError
      def initialize(message = "The provided id doesn't match any database.")
        super(message)
      end
    end
  end
end
