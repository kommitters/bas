# frozen_string_literal: true

module Domain
  ##
  # The Domain::Pto class provides a domain-specific representation of a Paid Time Off (PTO) object.
  # It encapsulates information about an individual's time off, including the individual's name,
  # the start date, and the end date of the time off period.
  #
  class Pto
    attr_reader :individual_name, :start_date_from, :start_date_to, :end_date_from, :end_date_to

    ATTRIBUTES = %w[individual_name start_date_from start_date_to end_date_from end_date_to].freeze

    # Initializes a Domain::Pto instance with the specified individual name, start date, and end date.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>String</tt> individual_name Name of the individual.
    # * <tt>DateTime</tt> start_date Start day of the PTO.
    # * <tt>String</tt> end_date End date of the PTO.
    #
    def initialize(individual_name, start_date, end_date)
      @individual_name = individual_name

      @start_date_from = start_date[:from]
      @start_date_to = start_date[:to]
      @end_date_from = end_date[:from]
      @end_date_to = end_date[:to]
    end

    def same_day?
      start_date = extract_date(start_date_from)
      end_date = extract_date(end_date_from)

      start_date == end_date
    end

    def format_timezone(timezone)
      @start_date_from = set_timezone(start_date_from, timezone)
      @start_date_to = set_timezone(start_date_to, timezone)
      @end_date_from = set_timezone(end_date_from, timezone)
      @end_date_to = set_timezone(end_date_to, timezone)
    end

    private

    def extract_date(date)
      return if date.nil?

      date.strftime("%F")
    end

    def build_date_time(date, timezone)
      return if date.nil?

      date_time = date.include?("T") ? date : "#{date}T00:00:00.000#{timezone}"

      DateTime.parse(date_time).to_time
    end

    def set_timezone(date, timezone)
      return if date.nil?

      date_time = build_date_time(date, timezone)

      Time.at(date_time, in: timezone)
    end
  end
end
