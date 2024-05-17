# frozen_string_literal: true

require_relative "../utils/exceptions/function_not_implemented"
require_relative "../utils/exceptions/invalid_process_response"
require_relative "../write/postgres_update"

module Bot
  ##
  # The Bot::Base class serves as the foundation for implementing specific bots. Operating
  # as an interface, this class defines essential attributes and methods, providing a blueprint
  # for creating custom bots formed by a Read, Process, and Write components.
  #
  class Base
    attr_reader :read_options, :process_options, :write_options
    attr_accessor :read_response, :process_response, :write_response

    def initialize(config)
      @read_options = config[:read_options]
      @process_options = config[:process_options]
      @write_options = config[:write_options]
    end

    def execute
      @read_response = read

      write_read_response_in_process

      @process_response = process
      raise Utils::Exceptions::InvalidProcessResponse unless process_response.is_a?(Hash)

      write_read_response_processed

      @write_response = write
    end

    protected

    def read
      raise Utils::Exceptions::FunctionNotImplemented
    end

    def process
      raise Utils::Exceptions::FunctionNotImplemented
    end

    def write
      raise Utils::Exceptions::FunctionNotImplemented
    end

    private

    def write_read_response_in_process
      options = { params: { stage: "in process" }, conditions: "id=#{read_response.id}" }

      Write::PostgresUpdate.new(read_options.merge(options)).execute
    end

    def write_read_response_processed
      options = { params: { stage: "processed" }, conditions: "id=#{read_response.id}" }

      Write::PostgresUpdate.new(read_options.merge(options)).execute
    end
  end
end
