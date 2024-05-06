# frozen_string_literal: true

require_relative "../utils/exceptions/function_not_implemented"
require_relative "../utils/exceptions/invalid_process_response"

module Bot
  ##
  # The Bot::Base class serves as the foundation for implementing specific bots. Operating
  # as an interface, this class defines essential attributes and methods, providing a blueprint
  # for creating custom bots formed by a Read, Process, and Write components.
  #
  class Base
    attr_reader :read_options, :process_options, :write_options

    def initialize(config)
      @read_options = config[:read_options]
      @process_options = config[:process_options]
      @write_options = config[:write_options]
    end

    def execute
      read_response = read

      process_response = process(read_response)
      raise Utils::Exceptions::InvalidProcessResponse unless process_response.is_a?(Hash)

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
