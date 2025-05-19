# frozen_string_literal: true

require "concurrent-ruby"
require "date"

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
          execute_custom_rule(script, @actual_time) if custom_rule?(script)

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

      def execute_custom_rule(script, current_moment)
        rule = script[:custom_rule]
        case rule[:type]
        when "last_day_of_week_in_month"
          execute_last_day_of_week_in_month(script, rule, current_moment)
        # when "last_day_of_month"
        #   exceute_last_day_of_month(script, rule, current_moment)
        else
          puts "Unknown custom rule type: #{rule[:type]} for script '#{script[:path]}'"
        end
      end

      def execute_last_day_of_week_in_month(script, rule, current_moment)
        time_str_from_moment = current_moment.strftime("%H:%M")
        return unless rule[:time]&.include?(time_str_from_moment)

        return unless today_is_last_day_of_week_in_month?(current_moment, rule[:day_of_week])

        execute(script) unless @last_executions.fetch(script[:path], nil).eql?(time_str_from_moment)
        @last_executions[script[:path]] = time_str_from_moment
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

      def custom_rule?(script)
        script[:custom_rule] && script[:custom_rule][:type]
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

      def today_is_last_day_of_week_in_month?(time_obj, target_day_name)
        date = time_obj.to_date 
        target_wday = Date::DAYNAMES.index { |name| name.casecmp(target_day_name) == 0 }

        return false if target_wday.nil?
        return false unless date.wday == target_wday

        year = date.year
        month = date.month

        first_day_of_next_month = if month == 12
                                    Date.new(year + 1, 1, 1)
                                  else
                                    Date.new(year, month + 1, 1)
                                  end

        last_day_of_current_month = first_day_of_next_month - 1
        current_check_date = last_day_of_current_month
        loop do
          break if current_check_date.month != month

          if current_check_date.wday == target_wday
            return date == current_check_date
          end
          current_check_date -= 1
        end
        false 
      end

      def execute(script)
        puts "Executing #{script[:path]} at #{current_time}"
        absolute_path = File.expand_path(script[:path], __dir__)

        system("ruby", absolute_path)
      end
    end
  end
end
