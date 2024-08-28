# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::FormatDoBillAlert class serves as a bot implementation to format DigitalOcean bill
  # alerts from a PostgresDB database, format them with a specific template, and write them on a
  # PostgresDB table with a specific format.
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
  #       db_table: "do_billing",
  #       tag: "FetchBillingFromDigitalOcean"
  #     },
  #     process_options: {
  #       threshold: 7
  #     },
  #     write_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "do_billing",
  #       tag: "FormatDoBillAlert"
  #     }
  #   }
  #
  #   bot = Bot::FormatDoBillAlert.new(options)
  #   bot.execute
  #
  class FormatDoBillAlert < Bot::Base
    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # Process function to format the notification using a template
    #
    def process
      return { success: { notification: "" } } if unprocessable_response || !threshold_exceeded

      { success: { notification: message } }
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

    def threshold_exceeded
      return false if billing.zero?

      usage > process_options[:threshold]
    end

    def usage
      billing - last_billing
    end

    def billing
      read_response.data["billing"]["month_to_date_balance"].to_f
    end

    def last_billing
      read_response.data["last_billing"]["month_to_date_balance"].to_f
    end

    def message
      balance = billing
      threshold = process_options[:threshold]

      ":warning: The **DigitalOcean** daily usage was exceeded. \
      Current balance: #{balance}, Threshold: #{threshold}, \
      Current daily usage: #{usage.round(3)}"
    end
  end
end
