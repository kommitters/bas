# frozen_string_literal: true

require_relative "../domain/work_items_limit"
require_relative "./exceptions/invalid_data"
require_relative "./base"

module Formatter
  ##
  # This class implements methods from the Formatter::Base module, tailored to format the
  # Domain::WorkItemsLimit structure for a dispatcher.
  class WorkItemsLimit < Base
    DEFAULT_DOMAIN_LIMIT = 6

    # Initializes the formatter with essential configuration parameters.
    #
    # <b>limits</b> : expect a map with the wip limits by domain. Example: { "ops": 5 }
    def initialize(config = {})
      super(config)

      @limits = config[:limits]
    end

    # Implements the logic for building a formatted payload with the given template for wip limits.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>List<Domain::WorkItemsLimit></tt> work_items_list: List of mapped work items limits.
    #
    # <br>
    # <b>raises</b> <tt>Formatter::Exceptions::InvalidData</tt> when invalid data is provided.
    #
    # <br>
    # <b>returns</b> <tt>String</tt> payload, formatted payload suitable for a Dispatcher.
    #

    def format(work_items_list)
      raise Formatter::Exceptions::InvalidData unless work_items_list.all? do |work_item|
        work_item.is_a?(Domain::WorkItemsLimit)
      end

      exceeded_domains(work_items_list).reduce("") do |payload, work_items_limit|
        built_template = build_template(Domain::WorkItemsLimit::ATTRIBUTES, work_items_limit)
        payload + format_message_by_case(built_template.gsub("\n", ""), work_items_limit)
      end
    end

    private

    def format_message_by_case(template, work_items_limit)
      total_items = work_items_limit.total
      limit = domain_limit(work_items_limit.domain)

      template + ", #{total_items} of #{limit}\n"
    end

    def exceeded_domains(work_items_list)
      work_items_list.filter { |work_item| work_item.total > domain_limit(work_item.domain) }
    end

    def domain_limit(domain)
      @limits[domain.to_sym] || DEFAULT_DOMAIN_LIMIT
    end
  end
end
