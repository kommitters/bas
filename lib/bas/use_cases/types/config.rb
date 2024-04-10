# frozen_string_literal: true

module UseCases
  module Types
    ##
    # Represents a the configuration composing the initial components required by a UseCases::UseCase implementation.
    #
    class Config
      attr_reader :read, :mapper, :formatter, :dispatcher

      def initialize(read, mapper, formatter, dispatcher)
        @read = read
        @mapper = mapper
        @formatter = formatter
        @dispatcher = dispatcher
      end
    end
  end
end
