# frozen_string_literal: true

module Read
  module Types
    ##
    # Represents a response from a read component. It encapsulates the requested data
    # from the <b>common storage</b> to be processed by a Bot.
    class Response
      attr_reader :data

      def initialize(response = {})
        @data = response
      end
    end
  end
end
