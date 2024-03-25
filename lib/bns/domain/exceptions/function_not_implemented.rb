# frozen_string_literal: true

module Domain
  module Exceptions
    ##
    # Provides a domain-specific representation for errors that occur when a function has not been implemented yet.
    # It inherits from StandardError # and allows developers to raise a specific exception when a required function
    # remains unimplemented in a subclass.
    #
    class FunctionNotImplemented < StandardError
      # Initializes the exception with an optional custom error message.
      #
      def initialize(message = "The function haven't been implemented yet.")
        super(message)
      end
    end
  end
end
