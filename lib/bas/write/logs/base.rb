# frozen_string_literal: true

require_relative "../base"

module Write
  module Logs
    ##
    # This class is an implementation of the Write::Base interface, specifically designed
    # for writting logs as a STDOUT.
    #
    class Base < Write::Base
      attr_reader :logger

      # Initializes the write with essential configuration parameters like the logger
      # using the Logger gem.
      #
      def initialize(config = {})
        super(config)

        @logger = Logger.new($stdout)
      end

      protected

      # Implements the writing logic to write logs data as STOUT. It uses the Logger
      # gem and execute the given method (info, error, etc) to write the log
      #
      def write(method, log_message)
        @logger.send(method, log_message)
      end
    end
  end
end
