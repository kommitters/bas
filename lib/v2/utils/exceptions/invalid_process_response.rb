# frozen_string_literal: true

module Utils
  module Exceptions
    class InvalidProcessResponse < StandardError
      def initialize(message = "The Process response should be a Hash type object")
        super(message)
      end
    end
  end
end
