# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../utils/notion/request"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::FetchBirthdaysFromNotion class serves as a bot implementation to read birthdays from a
  # notion database and write them on a PostgresDB table with a specific format.
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
  #       db_table: "use_cases",
  #       tag: "FetchBirthdaysFromNotion"
  #     }
  #   }
  #
  #   bot = Bot::FetchBirthdaysFromNotion.new(options)
  #   bot.execute
  #
  class FetchBirthdaysFromNotion < Bot::Base
    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # Process function to execute the Notion utility to fetch birthdays from a notion database
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
        where: "archived=$1 AND tag=$2 ORDER BY inserted_at DESC",
        params: [false, read_options[:tag]]
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
      today = Time.now.utc.strftime("%F").to_s

      {
        filter: {
          and: [{ property: "BD_this_year", date: { equals: today } }] + last_edited_condition
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
