# frozen_string_literal: true

require_relative "../base"

module Write
  module Logs
    class Base < Write::Base

      def initialize(config = {})
        super(config)

        @logger = Logger.new(STDOUT)
      end

      protected

      def write(log_message)
        @logger.info(log_message)
      end
    end
  end
end