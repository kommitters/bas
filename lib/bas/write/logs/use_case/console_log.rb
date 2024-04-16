# frozen_string_literal: true

require_relative "../base"

module Write
  module Logs
    ##
    # This class is an implementation of the Write::Logs::Base interface, specifically designed
    # to write logs as STDOUT
    class ConsoleLog < Logs::Base
      # Implements the writting process logic for the ConsoleLog use case.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Process::Types::Response</tt> process response: standard process response with the data to be logged.
      #
      def execute(_process_response)
        write("info", "Process Executed")
      end
    end
  end
end
