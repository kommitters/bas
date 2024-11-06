# frozen_string_literal: true

module SharedStorage
  module Types
    ##
    # Represents a response from a read component. It encapsulates the requested data
    # from the <b>shared storage</b> to be processed by a Bot.
    class Read
      attr_reader :id, :data, :inserted_at

      def initialize(id = nil, response = {}, inserted_at = nil)
        @id = id
        @data = response
        @inserted_at = inserted_at
      end
    end
  end
end
