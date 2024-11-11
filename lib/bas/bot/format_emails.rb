# frozen_string_literal: true

require_relative "./base"

module Bot
  ##
  # The Bot::FormatEmails class serves as a bot implementation to read emails from a
  # PostgresDB database, format them with a specific template, and write them on a PostgresDB
  # table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   read_options = {
  #     connection:,
  #     db_table: "support_emails",
  #     tag: "FetchEmailsFromImap"
  #   }
  #
  #   write_options = {
  #     connection:,
  #     db_table: "support_emails",
  #     tag: "FormatEmails"
  #   }
  #
  #   options = {
  #     template: "The <sender> has requested support the <date>",
  #     frequency: 5,
  #     timezone: "-05:00"
  #   }
  #
  #   shared_storage = SharedStorage::Postgres.new({ read_options:, write_options: })
  #
  #   Bot::FormatEmails.new(options, shared_storage).execute
  #
  class FormatEmails < Bot::Base
    EMAIL_ATTRIBUTES = %w[subject sender date].freeze
    DEFAULT_TIME_ZONE = "+00:00"

    # Process function to format the notification using a template
    #
    def process
      return { success: { notification: "" } } if unprocessable_response

      emails_list = read_response.data["emails"]

      notification = process_emails(emails_list).reduce("") do |payload, email|
        "#{payload} #{build_template(EMAIL_ATTRIBUTES, email)} \n"
      end

      { success: { notification: } }
    end

    private

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
