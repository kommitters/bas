# frozen_string_literal: true

require "date"

require_relative "../domain/pto"
require_relative "./exceptions/invalid_data"
require_relative "./base"
require_relative "./types/response"

module Formatter
  ##
  # This class implements methods from the Formatter::Base module, tailored to format the
  # Domain::Pto structure for a Process.
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
    # * <tt>List<Domain::Pto></tt> pto_list: List of serialized PTO's.
    #
    # <br>
    # <b>raises</b> <tt>Formatter::Exceptions::InvalidData</tt> when invalid data is provided.
    #
    # <br>
<<<<<<< Updated upstream
    # <b>returns</b> <tt>String</tt> payload, formatted payload suitable for a Process.
=======
    # <b>returns</b> <tt>Formatter::Types::Response</tt> formatter response: standard output for
    # the formatted payload suitable for a Processor.
>>>>>>> Stashed changes
    #

    def format(ptos_list)
      raise Formatter::Exceptions::InvalidData unless ptos_list.all? { |pto| pto.is_a?(Domain::Pto) }

      ptos_list.each { |pto| pto.format_timezone(@timezone) }

      response = ptos_list.reduce("") do |payload, pto|
        built_template = build_template(Domain::Pto::ATTRIBUTES, pto)
        payload + format_message_by_case(built_template.gsub("\n", ""), pto)
      end

      Formatter::Types::Response.new(response)
    end

    private

    def format_message_by_case(built_template, pto)
      if pto.same_day?
        interval = same_day_interval(pto)
        day_message = today?(pto.start_date_from) ? "today" : "the day #{pto.start_date_from.strftime("%F")}"

        "#{built_template} #{day_message} #{interval}\n"
      else
        start_date_interval = day_interval(pto.start_date_from, pto.start_date_to)
        end_date_interval = day_interval(pto.end_date_from, pto.end_date_to)

        "#{built_template} from #{start_date_interval} to #{end_date_interval}\n"
      end
    end

    def day_interval(start_date, end_date)
      return start_date.strftime("%F") if end_date.nil?

      time_start = start_date.strftime("%I:%M %P")
      time_end = end_date.strftime("%I:%M %P")

      "#{start_date.strftime("%F")} (#{time_start} - #{time_end})"
    end

    def same_day_interval(pto)
      time_start = pto.start_date_from.strftime("%I:%M %P")
      time_end = pto.end_date_from.strftime("%I:%M %P")

      time_start == time_end ? "all day" : "from #{time_start} to #{time_end}"
    end

    def today?(date)
      date == Time.now(in: @timezone).strftime("%F")
    end
  end
end
