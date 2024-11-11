# frozen_string_literal: true

require_relative "./base"
require_relative "../utils/notion/request"

module Bot
  ##
  # The Bot::FetchNextWeekBirthdaysFromNotion class serves as a bot implementation to read next
  # week birthdays from a notion database and write them on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   write_options = {
  #     connection:,
  #     db_table: "birthday",
  #     tag: "FetchNextWeekBirthdaysFromNotion"
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
  class FetchNextWeekBirthdaysFromNotion < Bot::Base
    DAYS_BEFORE = 7

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
