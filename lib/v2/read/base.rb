# frozen_string_literal: true

require_relative "../utils/exceptions/function_not_implemented"

module Read
  class Base
    attr_reader :config

    def initialize(config = {})
      @config = config
    end

    def execute
      raise Utils::Exceptions::FunctionNotImplemented
    end
  end
end
