# frozen_string_literal: true

module UseCases
  module Types
    ##
    # Represents a the configuration composing the initial components required by a UseCases::UseCase implementation.
    #
    class Config
      attr_reader :fetcher, :mapper, :formatter, :dispatcher

      def initialize(fetcher, mapper, formatter, dispatcher)
        @fetcher = fetcher
        @mapper = mapper
        @formatter = formatter
        @dispatcher = dispatcher
      end
    end
  end
end
