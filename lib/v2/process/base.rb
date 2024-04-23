# frozen_string_literal: true

require_relative "../utils/exceptions/function_not_implemented"

module Process
  class Base
    attr_reader :config, :read_response

    def initialize(config, read_response)
      @config = config
      @read_response = read_response
    end

    def execute
      raise Utils::Exceptions::FunctionNotImplemented
    end
  end
end
