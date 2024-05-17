# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
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
  #       tag: "FetchNextWeekBirthdaysFromNotion"
  #     }
  #   }
  #
  #   bot = Bot::FetchNextWeekBirthdaysFromNotion.new(options)
  #   bot.execute
  #
  class FetchNextWeekBirthdaysFromNotion < Bot::Base
    DAYS_BEFORE = 7

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # Process function to execute the Notion utility to fetch PTO's from the notion database
    #
    def process
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
          and: [{ property: "BD_this_year", date: { equals: n_days_from_now } }] + last_edited_condition
        }
      }
    end

    def last_edited_condition
      return [] if read_response.inserted_at.nil?

      [
        {
          timestamp: "last_edited_time",
          last_edited_time: { on_or_after: read_response.inserted_at }
        }
      ]
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
