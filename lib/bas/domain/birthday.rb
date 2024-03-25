# frozen_string_literal: true

module Domain
  ##
  # The Domain::Birthday class provides a domain-specific representation of a Birthday object.
  # It encapsulates the individual's name and their birthdate, offering a structured way to
  # handle and manipulate birthday information.
  class Birthday
    attr_reader :individual_name, :birth_date

    ATTRIBUTES = %w[individual_name birth_date].freeze

    # Initializes a Domain::Birthday instance with the specified individual name, and date of birth.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>String</tt> individual_name Name of the individual
    # * <tt>Date</tt> birth_date Birthdate from the individual
    #
    def initialize(individual_name, date)
      @individual_name = individual_name
      @birth_date = date
    end
  end
end
