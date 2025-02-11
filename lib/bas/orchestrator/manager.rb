# frozen_string_literal: true

require "concurrent-ruby"

module Bas
  module Orchestrator
    ##
    # Manager class responsible for scheduling and executing scripts concurrently.
    #
    # This class initializes a thread pool and processes scheduled scripts based on
    # time intervals, specific days, or exact times.
    #
    class Manager
      def initialize(schedules)
        @last_executions = Hash.new(0.0)
        @schedules = schedules
        @pool = Concurrent::FixedThreadPool.new(@schedules.size)
      end

      def run
        @schedules.each { |script| @pool.post { process_script(script) } }

        @pool.shutdown
        @pool.wait_for_termination
      end

      private

      def process_script(script)
        loop do
          @actual_time = Time.new

          execute_interval(script) if interval?(script)
          execute_day(script) if day?(script) && time?(script)
          execute_time(script) if time?(script) && !day?(script)

          sleep 0.1
        rescue StandardError => e
          puts "Error in thread: #{e.message}"
        end
      end

      def execute_interval(script)
        return unless time_in_milliseconds - @last_executions[script[:path]] >= script[:interval]

        execute(script)
        @last_executions[script[:path]] = time_in_milliseconds
      end

      def execute_day(script)
        return unless script[:day].include?(current_day) && script[:time].include?(current_time)

        execute(script) unless @last_executions[script[:path]].eql?(current_time)
        @last_executions[script[:path]] = current_time
      end

      def execute_time(script)
        execute(script) if script[:time].include?(current_time) && !@last_executions[script[:path]].eql?(current_time)
        @last_executions[script[:path]] = current_time
      end

      def interval?(script)
        script[:interval]
      end

      def time?(script)
        script[:time]
      end

      def day?(script)
        script[:day]
      end

      def time_in_milliseconds
        @actual_time.to_f * 1000
      end

      def current_time
        @actual_time.strftime("%H:%M")
      end

      def current_day
        @actual_time.strftime("%A")
      end

      def execute(script)
        puts "Executing #{script[:path]} at #{current_time}"
        absolute_path = File.expand_path(script[:path], __dir__)

        system("ruby", absolute_path)
      end
    end
  end
end
