# frozen_string_literal: true

require_relative './base.rb'
require_relative '../utils/notion/request'
require_relative './types/response'

module Process
  class PtoToday < Process::Base
    def execute
      response = Utils::Notion::Request.execute(params)

      body = JSON.parse(response.body)

      ptos = normalize_response(body['results'])

      Process::Types::Response.new(ptos)
    end

    private

    def params
      {
        endpoint: "databases/#{config[:database_id]}/query",
        secret: config[:secret],
        method: 'post',
        filter: ,
      }
    end

    def filter
      today = Time.now.utc.strftime("%F").to_s

      {
        filter: {
          "and": [
            { property: "Desde?", date: { on_or_before: today } },
            { property: "Hasta?", date: { on_or_after: today } }
          ]
        }
      }
    end

    def normalize_response(results)
      return [] if results.nil?

      results.map do |pto|
        pto_fields = pto["properties"]

        {
          "Description" => extract_description_field_value(pto_fields["Description"]),
          "Desde?" => extract_date_field_value(pto_fields["Desde?"]),
          "Hasta?" => extract_date_field_value(pto_fields["Hasta?"])
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
