# frozen_string_literal: true

require_relative "./base"
require_relative "../utils/notion/request"

module Bot
  ##
  # The Bot::FetchDomainServicesFromNotion class serves as a bot implementation to read
  # web domains from a notion database and write them on a PostgresDB table with a specific format.
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
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "web_availability",
  #       tag: "FetchDomainServicesFromNotion"
  #     }
  #   }
  #
  #   bot = Bot::FetchDomainServicesFromNotion.new(options)
  #   bot.execute
  #
  class FetchDomainServicesFromNotion < Bot::Base
    # Process function to execute the Notion utility to fetch web domains from a notion database
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
