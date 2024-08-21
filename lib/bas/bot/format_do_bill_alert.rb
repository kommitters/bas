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
      data = reader.execute

      @billing_data = data.first || {}
      @last_updated = parse_last_updated(@billing_data["updated_at"])
    end

    # Process function to format the notification using a template
    #
    def process
      return { success: { notification: "" } } if skip_processing?

      { success: { notification: message } }
    end

    # Write function to execute the PostgresDB write component
    #
    def write
      writer = Write::Postgres.new(write_options, process_response)

      writer.execute
    end

    private

    def current_month_data?
      return false unless @last_updated

      current_month = Time.now.utc.month
      last_updated_month = @last_updated.month

      current_month == last_updated_month
    end

    def conditions
      {
        where: "archived=$1 AND tag=$2 AND stage=$3 AND EXTRACT(MONTH FROM inserted_at) = $4 ORDER BY inserted_at ASC",
        params: [false, read_options[:tag], "unprocessed", Time.now.utc.month]
      }
    end

    def threshold_exceeded
      daily_usage > process_options[:threshold]
    end

    def projected_threshold_exceeded
      projected_month_total > process_options[:threshold]
    end

    def daily_usage
      balance = current_balance
      day_of_month = Time.now.utc.mday

      balance / day_of_month
    end

    def projected_month_total
      balance = current_balance
      days_in_month = total_days_in_month
      today = current_day_of_month

      average_daily_cost = calculate_average_daily_cost(balance, today)
      remaining_days = days_in_month - today

      balance + (average_daily_cost * remaining_days)
    end

    def message
      balance = current_balance
      threshold = process_options[:threshold]
      projected_total = projected_month_total

      ":warning: The **DigitalOcean** daily usage was exceeded. \
        Current balance: #{balance}, Threshold: #{threshold}, \
        Current daily usage: #{daily_usage.round(3)}, \
        Projected end-of-month total: #{projected_total.round(2)}, \
        Last updated: #{@last_updated.strftime("%Y-%m-%d %H:%M:%S")}"
    end

    def parse_last_updated(updated_at)
      Time.parse(updated_at) if updated_at
    end

    def skip_processing?
      unprocessable_response || !threshold_exceeded || !current_month_data?
    end

    def current_balance
      @billing_data["billing"]["month_to_date_balance"].to_f
    end

    def total_days_in_month
      Time.days_in_month(Time.now.month, Time.now.year)
    end

    def current_day_of_month
      Time.now.utc.mday
    end

    def calculate_average_daily_cost(balance, today)
      balance / today
    end
  end
end
