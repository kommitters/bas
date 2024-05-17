# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::CompareWipLimitCount class serves as a bot implementation to read domains wip limits and
  # counts from a PostgresDB database, compare the values to find exceeded counts, and write them on
  # a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     read_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "use_cases",
  #       tag: "FetchDomainsWipLimitFromNotion"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "use_cases",
  #       tag: "CompareWipLimitCount"
  #     }
  #   }
  #
  #   bot = Bot::CompareWipLimitCount.new(options)
  #   bot.execute
  #
  class CompareWipLimitCount < Bot::Base
    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # Process function to compare the domains wip counts and limits
    #
    def process
      return { success: { exceeded_domain_count: {} } } if unprocessable_response

      domains_limits = read_response.data["domains_limits"]
      domain_wip_count = read_response.data["domain_wip_count"]

      exceeded_domain_count = exceedded_counts(domains_limits, domain_wip_count)

      { success: { exceeded_domain_count: } }
    end

    # Write function to execute the PostgresDB write component
    #
    def write
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def conditions
      {
        where: "archived=$1 AND tag=$2 AND stage=$3 ORDER BY inserted_at ASC",
        params: [false, read_options[:tag], "unprocessed"]
      }
    end

    def unprocessable_response
      read_data = read_response.data

      read_data.nil? || read_data == {} || read_data["domains_limits"] == [] || read_data["domain_wip_count"] == []
    end

    def exceedded_counts(limits, counts)
      counts.to_a.map do |domain_wip_count|
        domain, count = domain_wip_count
        domain_limit = limits[domain]

        { domain:, exceeded: count - domain_limit } if count > domain_limit
      end.compact
    end
  end
end
