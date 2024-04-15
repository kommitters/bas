# frozen_string_literal: true

module UseCases
  module Types
    ##
    # Represents a the configuration composing the initial components required by a UseCases::UseCase implementation.
    #
    class Config
      attr_reader :read, :serialize, :formatter, :process, :write

      def initialize(read, serialize, formatter, process = Process::Base.new(), write = Write::Base.new())
        @read = read
        @serialize = serialize
        @formatter = formatter
        @process = process
        @write = write
      end
    end
  end
end
