# frozen_string_literal: true

require_relative "../utils/exceptions/function_not_implemented"

module Bas
  module SharedStorage
    # SharedStorage base interface
    #
    class Base
      attr_reader :read_options, :read_response, :write_response
      attr_accessor :write_options

      # Initializes the read with essential configuration parameters.
      #
      def initialize(options = {})
        @read_options = options[:read_options] || {}
        @write_options = options[:write_options] || {}
      end

      def set_in_process; end

      def set_processed; end

      def close_connections; end

      protected

      def read
        raise Utils::Exceptions::FunctionNotImplemented
      end

      def write
        raise Utils::Exceptions::FunctionNotImplemented
      end
    end
  end
end
