# frozen_string_literal: true

require_relative "./base"
require_relative "../utils/notion/request"

module Bot
  ##
  # The Bot::FetchDomainsWipLimitFromNotion class serves as a bot implementation to fetch domains wip
  # limits from a Notion database, merge them with the count of how many are by domain, and write them
  # on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     read_options: {
  #       connection: {
  #         host: "host",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "use_cases",
  #       tag: "FetchDomainsWipCountsFromNotion"
  #     },
  #     process_options: {
  #       database_id: "notion database id",
  #       secret: "notion secret"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "host",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "use_cases",
  #       tag: "FetchDomainsWipLimitFromNotion"
  #     }
  #   }
  #
  #   bot = Bot::FetchDomainsWipLimitFromNotion.new(options)
  #   bot.execute
  #
  class FetchDomainsWipLimitFromNotion < Bot::Base
    # Process function to execute the Notion utility to fetch domain wip limits from the notion database
    #
    def process
      response = Utils::Notion::Request.execute(params)

      if response.code == 200
        domains_limits = normalize_response(response.parsed_response["results"])

        wip_limit_data = wip_count.merge({ domains_limits: })

        { success: wip_limit_data }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

    private

    def params
      {
        endpoint: "databases/#{process_options[:database_id]}/query",
        secret: process_options[:secret],
        method: "post",
        body:
      }
    end

    def body
      {
        filter: {
          property: "WIP + On Hold limit",
          number: { is_not_empty: true }
        }
      }
    end

    def normalize_response(results)
      return [] if results.nil?

      results.reduce({}) do |domains_limits, domain_wip_limit|
        domain_fields = domain_wip_limit["properties"]

        domain = extract_domain_name_value(domain_fields["Name"])
        limit = extract_domain_limit_value(domain_fields["WIP + On Hold limit"])

        domains_limits.merge({ domain => limit })
      end
    end

    def extract_domain_name_value(data)
      data["title"].first["plain_text"]
    end

    def extract_domain_limit_value(data)
      data["number"]
    end

    def wip_count
      read_response.data.nil? ? {} : read_response.data
    end
  end
end
