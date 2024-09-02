# frozen_string_literal: true

require "httparty"

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"
require_relative "../utils/openai/run_assistant"

module Bot
  ##
  # The Bot::ReviewDomainAvailability class serves as a bot implementation to read from a postgres
  # shared storage a domain requests and review its availability.
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
  #       db_table: "web_availability",
  #       tag: "ReviewDomainRequest"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "web_availability",
  #       tag: "ReviewDomainAvailability"
  #     }
  #   }
  #
  #   bot = Bot::ReviewDomainAvailability.new(options)
  #   bot.execute
  #
  class ReviewDomainAvailability < Bot::Base
    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # process function to make a http request to the domain and check the status
    #
    def process
      return { success: { review: nil } } if unprocessable_response

      response = availability

      if response.code == 200
        { success: { review: nil } }
      else
        { success: { notification: notification(response) } }
      end
    end

    # write function to execute the PostgresDB write component
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

    def availability
      url = read_response.data["url"]

      HTTParty.get(url, {})
    end

    def notification(response)
      ":warning: The Domain #{read_response.data["url"]} is down with an error code of #{response.code}"
    end
  end
end
