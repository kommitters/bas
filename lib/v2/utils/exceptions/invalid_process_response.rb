# frozen_string_literal: true

module Utils
  module Exceptions
    ##
    # Representation for errors that occur when a process function of a Bot returns
    # something different than a Hash type object.
    # It inherits from StandardError.
    #
    class InvalidProcessResponse < StandardError
      def initialize(message = "The Process response should be a Hash type object")
        super(message)
      end
    end
  end
end
