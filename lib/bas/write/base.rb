# frozen_string_literal: true

require_relative "../domain/exceptions/function_not_implemented"

module Write
  class Base
    attr_reader :config

    def initialize(config = {})
      @logger = Logger.new(STDOUT)

      @config = config
    end

    def execute(_process_response)
      write
    end

    protected

    def write
      @logger.info("Process executed")
    end
  end
end
