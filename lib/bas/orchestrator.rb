# frozen_string_literal: true

require "bas/orchestrator/manager"
module Bas
  # The Orchestrator module is responsible for managing the scheduling and execution
  # of scripts within the business automation services. It provides a high-level
  # interface to start the orchestration process using the `Manager` class.
  #
  module Orchestrator
    # Starts the orchestration process with the given schedules.
    #
    # @param schedules [Array<Hash>] A list of scripts with execution details.
    def self.start(schedules)
      manager = Manager.new(schedules)
      manager.run
    end
  end
end
