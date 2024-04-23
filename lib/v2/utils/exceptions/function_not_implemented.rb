# frozen_string_literal: true

module Utils
  module Exceptions
    class FunctionNotImplemented < StandardError
      def initialize(message = "The function haven't been implemented yet.")
        super(message)
      end
    end
  end
end
