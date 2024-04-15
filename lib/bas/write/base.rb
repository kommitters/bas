# frozen_string_literal: true

require_relative "../domain/exceptions/function_not_implemented"

module Write
  class Base
    attr_reader :config

    def initialize(config = {})
      @config = config
    end

    def execute(_process_response)
      raise Domain::Exceptions::FunctionNotImplemented
    end

    protected

    def write(_data)
      raise Domain::Exceptions::FunctionNotImplemented
    end
  end
end
