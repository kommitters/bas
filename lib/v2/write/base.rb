# frozen_string_literal: true

require_relative "../utils/exceptions/function_not_implemented"

module Write
  class Base
    attr_reader :config, :process_response

    def initialize(config, process_response)
      @config = config
      @process_response = process_response
    end

    def execute
      raise Utils::Exceptions::FunctionNotImplemented
    end
  end
end
