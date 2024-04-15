# frozen_string_literal: true

module Formatter
  module Types
    ##
    # Represents a response received from a Formatter. It encapsulates the formatted data to be used by
    # a Process or a Write component.
    class Response
      attr_reader :data

      def initialize(response)
        @data = response
      end
    end
  end
end
