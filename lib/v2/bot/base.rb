# frozen_string_literal: true

require_relative '../utils/exceptions/function_not_implemented'

module Bot
  class Base
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def execute
      read_response = read()

      process_response = process(read_response)

      write(process_response)
    end

    protected

    def read
      raise Utils::Exceptions::FunctionNotImplemented
    end

    def process(_read_response)
      raise Utils::Exceptions::FunctionNotImplemented
    end

    def write(_process_response)
      raise Utils::Exceptions::FunctionNotImplemented
    end
  end
end
