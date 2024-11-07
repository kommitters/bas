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
  #       tag: "FetchBirthdaysFromNotion"
  #     },
  #     process_options: {
  #       template: "birthday template message"
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
  #       tag: "FormatBirthdays"
  #     }
  #   }
  #
  #   bot = Bot::FormatBirthdays.new(options)
  #   bot.execute
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
