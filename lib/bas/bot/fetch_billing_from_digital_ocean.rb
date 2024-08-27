# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../utils/digital_ocean/request"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::FetchBillingFromDigitalOcean class serves as a bot implementation to read digital
  # ocean current billing using the DigitalOcean API
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     process_options: {
  #       secret: "digital_ocean_secret_key"
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
  #       tag: "FetchBillingFromDigitalOcean"
  #     }
  #   }
  #
  #   bot = Bot::FetchBillingFromDigitalOcean.new(options)
  #   bot.execute
  #
  class FetchBillingFromDigitalOcean < Bot::Base
    # Read function to execute the default Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # Process function to execute the DigitalOcean utility to fetch bills
    #
    def process
      response = Utils::DigitalOcean::Request.execute(params)

      if response.code == 200
        { success: { billing: response.parsed_response, last_billing: } }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
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
        where: "archived=$1 AND tag=$2 ORDER BY inserted_at DESC",
        params: [false, read_options[:tag]]
      }
    end

    def params
      {
        endpoint: "customers/my/balance",
        secret: process_options[:secret],
        method: "get",
        body: {}
      }
    end

    def last_billing
      return read_response.data["billing"] unless read_response.data.nil?

      { month_to_date_balance: 0 }
    end
  end
end
