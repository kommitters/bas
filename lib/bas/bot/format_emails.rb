# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::FormatEmails class serves as a bot implementation to read emails from a
  # PostgresDB database, format them with a specific template, and write them on a PostgresDB
  # table with a specific format.
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
  #       tag: "FetchEmailsFromImap"
  #     },
  #     process_options: {
  #       template: "emails template message"
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
  #       tag: "FormatEmails"
  #     }
  #   }
  #
  #   bot = Bot::FormatEmails.new(options)
  #   bot.execute
  #
  class FormatEmails < Bot::Base
    EMAIL_ATTRIBUTES = %w[subject sender date].freeze
    DEFAULT_TIME_ZONE = "+00:00"

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # Process function to format the notification using a template
    #
    def process
      return { success: { notification: "" } } if read_response.data.nil? || read_response.data["emails"] == []

      emails_list = read_response.data["emails"]

      notification = process_emails(emails_list).reduce("") do |payload, email|
        "#{payload} #{build_template(EMAIL_ATTRIBUTES, email)} \n"
      end

      { success: { notification: } }
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

    def process_emails(emails)
      emails.each do |email|
        date = DateTime.parse(email["date"]).to_time
        email["date"] = at_timezone(date)
      end
      emails.filter! { |email| email["date"] > time_window } unless process_options[:frequency].nil?

      format_timestamp(emails)
    end

    def format_timestamp(emails)
      emails.each { |email| email["date"] = email["date"].strftime("%F %r") }
    end

    def time_window
      date_time = Time.now - (60 * 60 * process_options[:frequency])

      at_timezone(date_time)
    end

    def at_timezone(date)
      timezone = process_options[:timezone] || DEFAULT_TIME_ZONE

      Time.at(date, in: timezone)
    end

    def build_template(attributes, instance)
      template = process_options[:template]

      attributes.reduce(template) do |formated_template, attribute|
        formated_template.gsub("<#{attribute}>", instance[attribute].to_s)
      end
    end
  end
end
