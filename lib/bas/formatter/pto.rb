# frozen_string_literal: true

require "date"

require_relative "../domain/pto"
require_relative "./exceptions/invalid_data"
require_relative "./base"

module Formatter
  ##
  # This class implements methods from the Formatter::Base module, tailored to format the
  # Domain::Pto structure for a dispatcher.
  class Pto < Base
    DEFAULT_TIME_ZONE = "+00:00"

    # Initializes the Slack formatter with essential configuration parameters.
    #
    # <b>timezone</b> : expect an string with the time difference relative to the UTC. Example: "-05:00"
    def initialize(config = {})
      super(config)

      @timezone = config[:timezone] || DEFAULT_TIME_ZONE
    end

    # Implements the logic for building a formatted payload with the given template for PTO's.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>List<Domain::Pto></tt> pto_list: List of mapped PTO's.
    #
    # <br>
    # <b>raises</b> <tt>Formatter::Exceptions::InvalidData</tt> when invalid data is provided.
    #
    # <br>
    # <b>returns</b> <tt>String</tt> payload, formatted payload suitable for a Dispatcher.
    #

    def format(ptos_list)
      raise Formatter::Exceptions::InvalidData unless ptos_list.all? { |pto| pto.is_a?(Domain::Pto) }

      ptos_list.reduce("") do |payload, pto|
        built_template = build_template(Domain::Pto::ATTRIBUTES, pto)
        payload + format_message_by_case(built_template.gsub("\n", ""), pto)
      end
    end

    private

    def format_message_by_case(built_template, pto)
      date_start = format_timezone(pto.start_date).strftime("%F")
      date_end = format_timezone(pto.end_date).strftime("%F")

      if date_start == date_end
        interval = same_day_interval(pto)
        day_message = today?(date_start) ? "today" : "the day #{date_start}"

        "#{built_template} #{day_message} #{interval}\n"
      else
        "#{built_template} from #{date_start} to #{date_end}\n"
      end
    end

    def same_day_interval(pto)
      time_start = format_timezone(pto.start_date).strftime("%I:%M %P")
      time_end = format_timezone(pto.end_date).strftime("%I:%M %P")

      time_start == time_end ? "all day" : "from #{time_start} to #{time_end}"
    end

    def format_timezone(date)
      date_time = build_date(date)

      Time.at(date_time, in: @timezone)
    end

    def today?(date)
      time_now = Time.now.strftime("%F")

      date == format_timezone(time_now).strftime("%F")
    end

    def build_date(date)
      date_time = date.include?("T") ? date : "#{date}T00:00:00.000#{@timezone}"

      DateTime.parse(date_time).to_time
    end
  end
end
