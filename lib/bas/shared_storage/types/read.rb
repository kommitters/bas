# frozen_string_literal: true

require "json"

module Bas
  module SharedStorage
    module Types
      ##
      # Represents a response from a read component. It encapsulates the requested data
      # from the <b>shared storage</b> to be processed by a Bot.
      class Read
        attr_reader :id, :data, :inserted_at

        def initialize(id = nil, response = nil, inserted_at = nil)
          @id = id
          @data = response.nil? ? {} : JSON.parse(response)
          @inserted_at = inserted_at
        end
      end
    end
  end
end
