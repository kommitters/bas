# frozen_string_literal: true

require_relative "../utils/exceptions/function_not_implemented"

module SharedStorage
  # SharedStorage base interface
  #
  class Base
    attr_reader :read_options, :write_options, :read_response, :write_response

    # Initializes the read with essential configuration parameters.
    #
    def initialize(options = {})
      @read_options = options[:read_options] || {}
      @write_options = options[:write_options] || {}
    end

    def set_in_process; end

    def set_processed; end

    protected

    def read
      raise Utils::Exceptions::FunctionNotImplemented
    end

    def write
      raise Utils::Exceptions::FunctionNotImplemented
    end
  end
end
