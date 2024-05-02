# frozen_string_literal: true

require_relative "./base"
require_relative "../read/default"
require_relative "../utils/notion/request"
require_relative "../write/postgres"

module Bot
  class FetchPtosFromNotion < Bot::Base
    def read
      reader = Read::Default.new

      reader.execute
    end

    def process(_read_response)
      response = Utils::Notion::Request.execute(params)

      if response.code == 200
        ptos_list = normalize_response(response.parsed_response["results"])

        { success: { ptos: ptos_list } }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

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
      today = Time.now.utc.strftime("%F").to_s

      {
        filter: {
          "and": [
            { property: "StartDateTime", date: { on_or_before: today } },
            { property: "EndDateTime", date: { on_or_after: today } }
          ]
        }
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
