# frozen_string_literal: true

module UseCases
  module Types
    ##
    # Represents a the configuration composing the initial components required by a UseCases::UseCase implementation.
    #
    class Config
      attr_reader :read, :serialize, :formatter, :dispatcher

      def initialize(read, serialize, formatter, dispatcher)
        @read = read
        @serialize = serialize
        @formatter = formatter
        @dispatcher = dispatcher
      end
    end
  end
end
