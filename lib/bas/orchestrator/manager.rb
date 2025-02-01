# frozen_string_literal: true

# The Bas module serves as a namespace for business automation services.
#
module Bas
  # The Orchestrator module is responsible for managing the scheduling and execution
  # of scripts within the business automation services.
  #
  module Orchestrator
    # The Manager class handles the scheduling and execution of scripts.
    class Manager
      # Initializes the Manager with a set of schedules.
      #
      # @param schedules [Array<Hash>] List of scripts with execution details.
      def initialize(schedules)
        @last_executions = Hash.new(0.0)
        @schedules = schedules
      end

      # Runs the execution loop, checking which scripts need to be executed.
      def run
        loop do
          @actual_time = Time.now

          @schedules.each do |script|
            execute(script) if should_execute?(script)
          end

          sleep 0.01
        end
      end

      private

      # Determines whether a script should be executed.
      #
      # @param script [Hash] The script schedule details.
      # @return [Boolean] True if the script should be executed, false otherwise.
      def should_execute?(script)
        return time_elapsed?(script) if script[:interval]
        return day_match?(script) && time_match?(script) if script[:day]

        time_match?(script)
      end

      # Executes a script and updates its last execution timestamp.
      #
      # @param script [Hash] The script schedule details.
      def execute(script)
        project_root = File.expand_path(File.join(__dir__, "..", "..", "..", ".."))
        script_path = File.expand_path(File.join(project_root, "src", "use_cases_execution",
                                                 script[:path].sub(%r{^src/use_cases_execution/}, "")))

        puts "Executing #{script_path} at #{current_time}"

        if system("ruby", script_path)
          @last_executions[script[:path]] = time_in_milliseconds
        else
          puts "Failed to execute #{script_path}"
        end
      end

      # Checks if the required time has elapsed for a script to run.
      #
      # @param script [Hash] The script schedule details.
      # @return [Boolean] True if the required interval has passed, false otherwise.
      def time_elapsed?(script)
        current_time_ms = time_in_milliseconds
        last_execution_ms = @last_executions[script[:path]] || 0
        current_time_ms - last_execution_ms >= script[:interval]
      end

      # Checks if the current time matches the script's scheduled time.
      #
      # @param script [Hash] The script schedule details.
      # @return [Boolean] True if the script should run now, false otherwise.
      def time_match?(script)
        script[:time]&.include?(current_time)
      end

      # Checks if the current day matches the script's scheduled day.
      #
      # @param script [Hash] The script schedule details.
      # @return [Boolean] True if today matches the scheduled day, false otherwise.
      def day_match?(script)
        script[:day]&.include?(current_day)
      end

      # Returns the current time in milliseconds.
      #
      # @return [Float] The current time in milliseconds.
      def time_in_milliseconds
        @actual_time.to_f * 1000
      end

      # Returns the current time in HH:MM format.
      #
      # @return [String] The current time as a string.
      def current_time
        @actual_time.strftime("%H:%M")
      end

      # Returns the current day of the week.
      #
      # @return [String] The current day as a string.
      def current_day
        @actual_time.strftime("%A")
      end
    end
  end
end
