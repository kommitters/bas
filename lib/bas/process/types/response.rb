# frozen_string_literal: true

module Process
  module Types
    ##
    # Represents a response received from a Process. It encapsulates the formatted data to be used by
    # a Write component.
    class Response
      attr_reader :data

      def initialize(response)
        @data = response
      end
    end
  end
end
