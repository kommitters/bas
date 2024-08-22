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

      @previous_billing_data = fetch_previous_billing_data
      @current_billing_data = reader.execute
    end

    # Process function to format the notification using a template
    #
    def process
      return { success: { notification: message } } if balance_alert?

      { success: { notification: "" } }
    end

    # Write function to execute the PostgresDB write component
    #
    def write
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def fetch_previous_billing_data
      previous_reader = Read::Postgres.new(read_options.merge(previous_conditions))
      previous_reader.execute
    end

    def previous_conditions
      {
        where: "archived=$1 AND tag=$2 AND stage=$3 ORDER BY inserted_at DESC LIMIT 1",
        params: [false, read_options[:tag], "processed"]
      }
    end

    def balance_alert?
      unprocessable_response || significant_change? || threshold_exceeded
    end

    def significant_change?
      previous_balance = @previous_billing_data["billing"]["month_to_date_balance"].to_f
      current_balance = @current_billing_data["billing"]["month_to_date_balance"].to_f

      (current_balance - previous_balance) > process_options[:threshold]
    end

    def conditions
      {
        where: "archived=$1 AND tag=$2 AND stage=$3 ORDER BY inserted_at ASC",
        params: [false, read_options[:tag], "unprocessed"]
      }
    end

    def threshold_exceeded
      daily_usage > process_options[:threshold]
    end

    def daily_usage
      balance = read_response.data["billing"]["month_to_date_balance"].to_f
      day_of_month = Time.now.utc.mday

      balance / day_of_month
    end

    def message
      balance = read_response.data["billing"]["month_to_date_balance"].to_f
      threshold = process_options[:threshold]

      ":warning: The **DigitalOcean** daily usage was exceeded. \
      Current balance: #{balance}, Threshold: #{threshold}, \
      Current daily usage: #{daily_usage.round(3)}"
    end
  end
end
