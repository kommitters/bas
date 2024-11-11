# frozen_string_literal: true

require "date"

require_relative "./base"
require_relative "../utils/notion/request"

module Bot
  ##
  # The Bot::FetchPtosFromNotion class serves as a bot implementation to read PTO's from a
  # notion database and write them on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     database_id: "notion_database_id",
  #     secret: "notion_secret"
  #   }
  #
  #   write_options = {
  #     connection:,
  #     db_table: "pto",
  #     tag: "FetchPtosFromNotion"
  #   }
  #
  #   shared_storage_reader = SharedStorage::Default.new
  #   shared_storage_writer = SharedStorage::Postgres.new({ write_options: })
  #
  #   Bot::FetchPtosFromNotion.new(options, shared_storage_reader, shared_storage_writer).execute
  #
  class FetchPtosFromNotion < Bot::Base
    # Process function to execute the Notion utility to fetch PTO's from the notion database
    #
    def process
      response = Utils::Notion::Request.execute(params)

      if response.code == 200
        ptos_list = normalize_response(response.parsed_response["results"])

        { success: { ptos: ptos_list } }
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
        body: { filter: today_condition }
      }
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

        name = extract_description_field_value(pto_fields["Description"])
        start_date = extract_date_field_value(pto_fields["StartDateTime"])
        end_date = extract_date_field_value(pto_fields["EndDateTime"])

        description(name, start_date, end_date)
      end
    end

    def description(name, start_date, end_date)
      start = start_description(start_date)
      finish = end_description(end_date)

      "#{name} will not be working between #{start} and #{finish}. And returns the #{returns(finish)}"
    end

    def start_description(date)
      date[:from]
    end

    def end_description(date)
      return date[:from] if date[:to].nil?

      date[:to]
    end

    def returns(date)
      date.include?("T12") ? "#{date} in the afternoon" : next_work_day(date)
    end

    def next_work_day(date)
      datetime = DateTime.parse(date)

      return_day = case datetime.wday
                   when 5 then datetime + 3
                   when 6 then datetime + 2
                   else datetime + 1
                   end

      return_day.strftime("%A %B %d of %Y").to_s
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
