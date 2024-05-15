# frozen_string_literal: true

require_relative "./base"
require_relative "../read/default"
require_relative "../utils/notion/request"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::FetchNextWeekBirthdaysFromNotion class serves as a bot implementation to read next
  # week birthdays from a notion database and write them on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     process_options: {
  #       database_id: "notion database id",
  #       secret: "notion secret"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "host",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "birthdays",
  #       bot_name: "FetchNextWeekBirthdaysFromNotion"
  #     }
  #   }
  #
  #   bot = Bot::FetchNextWeekBirthdaysFromNotion.new(options)
  #   bot.execute
  #
  class FetchNextWeekBirthdaysFromNotion < Bot::Base
    DAYS_BEFORE = 7

    # Read function to execute the default Read component
    #
    def read
      reader = Read::Default.new

      reader.execute
    end

    # Process function to execute the Notion utility to fetch PTO's from the notion database
    #
    def process(_read_response)
      response = Utils::Notion::Request.execute(params)

      if response.code == 200
        birthdays_list = normalize_response(response.parsed_response["results"])

        { success: { birthdays: birthdays_list } }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

    # Write function to execute the PostgresDB write component
    #
    def write(process_response)
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def params
      {
        endpoint: "databases/#{process_options[:database_id]}/query",
        secret: process_options[:secret],
        method: "post",
        body:
      }
    end

    def body
      {
        filter: {
          or: [
            { property: "BD_this_year", date: { equals: n_days_from_now } }
          ]
        }
      }
    end

    def n_days_from_now
      date = Time.now.utc + days_in_second(days_before)

      date.utc.strftime("%F").to_s
    end

    def days_before
      process_options[:days_before] || DAYS_BEFORE
    end

    def days_in_second(days)
      days * 24 * 60 * 60
    end

    def normalize_response(results)
      return [] if results.nil?

      results.map do |value|
        birthday_fields = value["properties"]

        {
          "name" => extract_rich_text_field_value(birthday_fields["Complete Name"]),
          "birthday_date" => extract_date_field_value(birthday_fields["BD_this_year"])
        }
      end
    end

    def extract_rich_text_field_value(data)
      data["rich_text"][0]["plain_text"]
    end

    def extract_date_field_value(data)
      data["formula"]["date"]["start"]
    end
  end
end
