# frozen_string_literal: true

require_relative "../base"

module Write
  module Logs
    class ConsoleLog < Logs::Base
      def execute(_process_response)
        write("Process Executed")
      end
    end
  end
end