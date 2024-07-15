# frozen_string_literal: true

require_relative "./base"
require_relative "../read/default"
require_relative "../utils/notion/request"
require_relative "../write/postgres"

module Bot
  class FetchDomainServicesFromNotion < Bot::Base
    def read
      reader = Read::Default.new

      reader.execute
    end

    # Process function to execute the Notion utility to fetch media from a notion database
    #
    def process
      response = Utils::Notion::Request.execute(params)

      if response.code == 200
        urls_list = normalize_response(response.parsed_response["results"])

        { success: { urls: urls_list } }
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

    def params
      {
        endpoint: "databases/#{process_options[:database_id]}/query",
        secret: process_options[:secret],
        method: "post",
        body: {}
      }
    end

    def normalize_response(results)
      return [] if results.nil?

      results.map do |value|
        properties = value["properties"]

        {
          "url" => extract_rich_text_field_value(properties["domain"])
        }
      end
    end

    def extract_rich_text_field_value(data)
      data["rich_text"][0]["plain_text"]
    end
  end
end
