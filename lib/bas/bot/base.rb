# frozen_string_literal: true

require_relative "../utils/exceptions/function_not_implemented"
require_relative "../utils/exceptions/invalid_process_response"

module Bas
  module Bot
    ##
    # The Bot::Base class serves as the foundation for implementing specific bots. Operating
    # as an interface, this class defines essential attributes and methods, providing a blueprint
    # for creating custom bots formed by a Read, Process, and Write components.
    #
    class Base
      attr_reader :process_options, :shared_storage_reader, :shared_storage_writer
      attr_accessor :read_response, :process_response, :write_response

      def initialize(options, shared_storage_reader, shared_storage_writer = nil)
        default_options = { close_connections_after_process: true }
        @process_options = default_options.merge(options || {})
        @shared_storage_reader = shared_storage_reader
        @shared_storage_writer = shared_storage_writer || shared_storage_reader
      end

      def execute
        @read_response = read

        @shared_storage_reader.set_in_process

        @process_response = process
        raise Utils::Exceptions::InvalidProcessResponse unless process_response.is_a?(Hash)

        @shared_storage_reader.set_processed

        @write_response = write

        close_connections if @process_options[:close_connections_after_process].eql?(true)
      end

      protected

      def read
        @shared_storage_reader.read
      end

      def process
        raise Utils::Exceptions::FunctionNotImplemented
      end

      def write
        return if @process_options[:avoid_empty_data] && empty_data?

        @shared_storage_writer.write(process_response)
      end

      def empty_data?
        process_response.nil? || process_response == {} || process_response.any? do |_key, value|
          [[], "", nil, {}].include?(value)
        end
      end

      def unprocessable_response
        read_data = read_response.data

        read_data.nil? || read_data == {} || read_data.any? { |_key, value| [[], "", nil].include?(value) }
      end

      def close_connections
        @shared_storage_reader.close_connections if @shared_storage_reader.respond_to?(:close_connections)
        @shared_storage_writer.close_connections if @shared_storage_writer.respond_to?(:close_connections)
      end
    end
  end
end
