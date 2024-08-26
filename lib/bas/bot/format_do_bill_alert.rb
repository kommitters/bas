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
      reader = Read::Postgres.new(read_options.merge(combined_conditions))

      @previous_billing_data, @current_billing_data = split_billing_data(reader.execute)
    end

    # Process function to format the notification using a template
    #
    def process
      return { success: { notification: message } } if balance_alert?

      { success: { notification: "" } } unless unprocessable_response
    end

    # Write function to execute the PostgresDB write component
    #
    def write
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def combined_conditions
      {
        where: "archived=$1 AND tag=$2 AND (stage=$3 OR stage=$4) ORDER BY inserted_at ASC",
        params: [false, read_options[:tag], "unprocessed", "processed"]
      }
    end

    def split_billing_data(billing_data)
      processed = billing_data.select { |record| record["stage"] == "processed" }.last
      unprocessed = billing_data.select { |record| record["stage"] == "unprocessed" }.first

      [processed, unprocessed]
    end

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
      significant_change? || threshold_exceeded
    end

    def significant_change?
      previous_balance = @previous_billing_data["billing"]["month_to_date_balance"].to_f
      current_balance = @current_billing_data["billing"]["month_to_date_balance"].to_f

      (current_balance - previous_balance) > process_options[:threshold]
    end

    def threshold_exceeded
      daily_usage > process_options[:threshold]
    end

    def daily_usage # rubocop:disable Metrics/AbcSize
      balance = read_response.data["billing"]["month_to_date_balance"].to_f
      current_time = Time.now.utc
      day_of_month = current_time.mday

      reset_period_start = Time.utc(current_time.year, current_time.month, current_time.day, 0, 0, 0)
      reset_period_end = reset_period_start + (3.5 * 3600)

      in_grace_period = current_time >= reset_period_start && current_time <= reset_period_end

      previous_balance = @previous_billing_data["billing"]["month_to_date_balance"].to_f
      current_balance = @current_billing_data["billing"]["month_to_date_balance"].to_f

      return current_balance - previous_balance if day_of_month == 1 && in_grace_period

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
