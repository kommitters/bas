# frozen_string_literal: true

module UseCases
  module Types
    ##
    # Represents a the configuration composing the initial components required by a UseCases::UseCase implementation.
    #
    class Config
      attr_reader :read, :serialize, :formatter, :process

      def initialize(read, serialize, formatter, process)
        @read = read
        @serialize = serialize
        @formatter = formatter
        @process = process
      end
    end
  end
end
