# frozen_string_literal: true

require_relative "./base"
require_relative "../utils/notion/request"

module Bot
  ##
  # The Bot::FetchBirthdaysFromNotion class serves as a bot implementation to read birthdays from a
  # notion database and write them on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   write_options = {
  #     connection:,
  #     db_table: "birthday",
  #     tag: "FetchBirthdaysFromNotion"
  #   }
  #
  #   options = {
  #     database_id: "notion_database_id",
  #     secret: "notion_secret"
  #   }
  #
  #   shared_storage_reader = SharedStorage::Default.new
  #   shared_storage_writer = SharedStorage::Postgres.new({ write_options: })
  #
  #   Bot::FetchBirthdaysFromNotion.new(options, shared_storage_reader, shared_storage_writer).execute
  #
  class FetchBirthdaysFromNotion < Bot::Base
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
