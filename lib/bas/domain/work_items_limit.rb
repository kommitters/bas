# frozen_string_literal: true

module Domain
  ##
  # The Domain::WorkItemsLimit class provides a domain-specific representation of a Work Item object.
  # It encapsulates information about a work items limit, including the domain and total.
  #
  class WorkItemsLimit
    attr_reader :domain, :total

    ATTRIBUTES = %w[domain total].freeze

    # Initializes a Domain::WorkItemsLimit instance with the specified domain and total.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>String</tt> 'domain' responsible domain of the work items.
    # * <tt>String</tt> 'total' total 'in progress' work items.
    #
    def initialize(domain, total)
      @domain = domain
      @total = total
    end
  end
end
