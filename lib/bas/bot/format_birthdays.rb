# frozen_string_literal: true

require_relative "./base"

module Bot
  ##
  # The Bot::FormatBirthdays class serves as a bot implementation to read birthdays from a
  # PostgresDB database, format them with a specific template, and write them on a PostgresDB
  # table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   read_options = {
  #     connection:,
  #     db_table: "birthday",
  #     tag: "FetchBirthdaysFromNotion"
  #   }
  #
  #   write_options = {
  #     connection:,
  #     db_table: "birthday",
  #     tag: "FormatBirthdays"
  #   }
  #
  #   options = {
  #     template: "The Birthday of <name> is today! (<birthday_date>) :birthday: :gift:"
  #   }
  #
  #   shared_storage = SharedStorage::Postgres.new({ read_options:, write_options: })
  #
  #   Bot::FormatBirthdays.new(options, shared_storage).execute
  #
  class FormatBirthdays < Bot::Base
    BIRTHDAY_ATTRIBUTES = %w[name birthday_date].freeze

    # Process function to format the notification using a template
    #
    def process
      return { success: { notification: "" } } if unprocessable_response

      birthdays_list = read_response.data["birthdays"]

      notification = birthdays_list.reduce("") do |payload, birthday|
        "#{payload} #{build_template(BIRTHDAY_ATTRIBUTES, birthday)} \n"
      end

      { success: { notification: } }
    end

    private

    def build_template(attributes, instance)
      template = process_options[:template]

      attributes.reduce(template) do |formated_template, attribute|
        formated_template.gsub("<#{attribute}>", instance[attribute].to_s)
      end
    end
  end
end
