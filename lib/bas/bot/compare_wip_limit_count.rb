# frozen_string_literal: true

require_relative "./base"

module Bot
  ##
  # The Bot::CompareWipLimitCount class serves as a bot implementation to read domains wip limits and
  # counts from a PostgresDB database, compare the values to find exceeded counts, and write them on
  # a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #  read_options = {
  #    connection:,
  #    db_table: "wip_limits",
  #    tag: "FetchDomainsWipLimitFromNotion"
  #  }
  #
  #  write_options = {
  #    connection:,
  #    db_table: "wip_limits",
  #    tag: "CompareWipLimitCount"
  #  }
  #
  #  options = {}
  #
  #  shared_storage = SharedStorage::Postgres.new({ read_options:, write_options: })
  #
  #  Bot::CompareWipLimitCount.new(options, shared_storage).execute
  #
  class CompareWipLimitCount < Bot::Base
    # Process function to compare the domains wip counts and limits
    #
    def process
      return { success: { exceeded_domain_count: {} } } if unprocessable_response

      domains_limits = read_response.data["domains_limits"]
      domain_wip_count = read_response.data["domain_wip_count"]

      exceeded_domain_count = exceeded_counts(domains_limits, domain_wip_count)

      { success: { exceeded_domain_count: } }
    end

    private

    def exceeded_counts(limits, counts)
      counts.to_a.map do |domain_wip_count|
        domain, count = domain_wip_count
        domain_limit = limits[domain]

        { domain:, exceeded: count - domain_limit } if count > domain_limit
      end.compact
    end
  end
end
