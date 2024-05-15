# frozen_string_literal: true

require_relative "./base"
require_relative "../read/default"
require_relative "../utils/notion/request"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::FetchPtosFromNotion class serves as a bot implementation to read PTO's from a
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
  #       db_table: "pto",
  #       bot_name: "FetchPtosFromNotion"
  #     }
  #   }
  #
  #   bot = Bot::FetchPtosFromNotion.new(options)
  #   bot.execute
  #
  class FetchPtosFromNotion < Bot::Base
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
        ptos_list = normalize_response(response.parsed_response["results"])

        { success: { ptos: ptos_list } }
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
      { filter: { "or": conditions } }
    end

    def conditions
      [
        today_condition,
        { property: "StartDateTime", date: { this_week: {} } },
        { property: "EndDateTime", date: { this_week: {} } },
        { property: "StartDateTime", date: { next_week: {} } },
        { property: "EndDateTime", date: { next_week: {} } }
      ]
    end

    def today_condition
      today = Time.now.utc.strftime("%F").to_s
      {
        "and": [
          { property: "StartDateTime", date: { on_or_before: today } },
          { property: "EndDateTime", date: { on_or_after: today } }
        ]
      }
    end

    def normalize_response(results)
      return [] if results.nil?

      results.map do |pto|
        pto_fields = pto["properties"]

        {
          "Name" => extract_description_field_value(pto_fields["Description"]),
          "StartDateTime" => extract_date_field_value(pto_fields["StartDateTime"]),
          "EndDateTime" => extract_date_field_value(pto_fields["EndDateTime"])
        }
      end
    end

    def extract_description_field_value(data)
      names = data["title"].map { |name| name["plain_text"] }

      names.join(" ")
    end

    def extract_date_field_value(date)
      {
        from: extract_start_date(date),
        to: extract_end_date(date)
      }
    end

    def extract_start_date(data)
      data["date"]["start"]
    end

    def extract_end_date(data)
      data["date"]["end"]
    end
  end
end
