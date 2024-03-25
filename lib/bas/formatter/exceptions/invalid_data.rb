# frozen_string_literal: true

module Formatter
  module Exceptions
    ##
    # Provides a domain-specific representation for errors that occurs when trying to process invalid
    # data on a Fetcher::Base implementation
    #
    class InvalidData < StandardError
      def initialize(message = "")
        super(message)
      end
    end
  end
end
