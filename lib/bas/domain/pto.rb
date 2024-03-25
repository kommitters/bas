# frozen_string_literal: true

module Domain
  ##
  # The Domain::Pto class provides a domain-specific representation of a Paid Time Off (PTO) object.
  # It encapsulates information about an individual's time off, including the individual's name,
  # the start date, and the end date of the time off period.
  #
  class Pto
    attr_reader :individual_name, :start_date, :end_date

    ATTRIBUTES = %w[individual_name start_date end_date].freeze

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
      @start_date = start_date
      @end_date = end_date
    end
  end
end
