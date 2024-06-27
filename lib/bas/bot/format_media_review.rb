# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"
require_relative "../utils/openai/run_assistant"

module Bot
  ##
  # The Bot::FormatMediaReview class serves as a bot implementation to read from a postgres
  # shared storage reviewed media request and format it to Notion blocks.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     read_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "review_media",
  #       tag: "ReviewText"
  #     },
  #     process_options: {
  #       secret: "openai_secret",
  #       assistant_id: "openai_assistant_id"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "review_media",
  #       tag: "FormatMediaReview"
  #     }
  #   }
  #
  #   bot = Bot::FormatMediaReview.new(options)
  #   bot.execute
  #
  class FormatMediaReview < Bot::Base
    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # process function to execute the OpenaAI utility to format the review request to notion Blocks
    #
    def process
      return { success: { formated_review: nil } } if unprocessable_response

      response = Utils::OpenAI::RunAssitant.execute(params)

      if response.code != 200 || (!response["status"].nil? && response["status"] != "completed")
        return error_response(response)
      end

      sucess_response(response)
    end

    # write function to execute the PostgresDB write component
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
        assistant_id: process_options[:assistant_id],
        secret: process_options[:secret],
        prompt: read_response.data["review"]
      }
    end

    def response_data(response)
      response.parsed_response["data"].first["content"].first["text"]["value"]
    end

    def sucess_response(response)
      review = response_data(response)
      page_id = read_response.data["page_id"]
      created_by = read_response.data["created_by"]
      property = read_response.data["property"]
      media_type = read_response.data["media_type"]

      { success: { review:, page_id:, created_by:, property:, media_type: } }
    end

    def error_response(response)
      { error: { message: response.parsed_response, status_code: response.code } }
    end
  end
end
