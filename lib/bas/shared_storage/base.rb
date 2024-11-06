# frozen_string_literal: true

require_relative "../utils/exceptions/function_not_implemented"

module SharedStorage
  # SharedStorage base interface
  #
  class Base
    attr_reader :read_options, :write_options

    # Initializes the read with essential configuration parameters.
    #
    def initialize(options)
      @read_options = options[:read_options] || {}
      @write_options = options[:write_options] || {}
    end

    protected

    def read
      raise Utils::Exceptions::FunctionNotImplemented
    end

    def write
      raise Utils::Exceptions::FunctionNotImplemented
    end
  end
end
