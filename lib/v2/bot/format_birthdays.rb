# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"

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
  #       bot_name: "FetchBirthdaysFromNotion"
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
  #       bot_name: "FormatBirthdays"
  #     }
  #   }
  #
  #   bot = Bot::FormatBirthdays.new(options)
  #   bot.execute
  #
  class FormatBirthdays < Bot::Base
    BIRTHDAY_ATTRIBUTES = %w[name birthday_date].freeze

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options)

      reader.execute
    end

    # Process function to format the notification using a template
    #
    def process(read_response)
      return { success: { notification: "" } } if read_response.data.nil? || read_response.data["birthdays"] == []

      birthdays_list = read_response.data["birthdays"]

      notification = birthdays_list.reduce("") do |payload, birthday|
        "#{payload} #{build_template(BIRTHDAY_ATTRIBUTES, birthday)} \n"
      end

      { success: { notification: } }
    end

    # Write function to execute the PostgresDB write component
    #
    def write(process_response)
      write = Write::Postgres.new(write_options, process_response)

      write.execute
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
