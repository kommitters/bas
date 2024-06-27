# frozen_string_literal: true

require_relative "./base"
require_relative "../read/default"
require_relative "../utils/notion/request"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::UpdateReviewMediaStatus class serves as a bot implementation to read from a postgres
  # shared storage updated status and update a parameter on a Notion database.
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
  #       tag: "WriteMediaReviewInNotion"
  #     },
  #     process_options: {
  #       secret: "notion_secret"
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
  #       tag: "UpdateReviewMediaStatus"
  #     }
  #   }
  #
  #   bot = Bot::UpdateReviewMediaStatus.new(options)
  #   bot.execute
  #
  class UpdateReviewMediaStatus < Bot::Base
    READY_STATE = "ready"

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # process function to execute the Notion utility to update a Notion database property
    #
    def process
      return { success: { status_updated: nil } } if unprocessable_response

      response = Utils::Notion::Request.execute(params)

      if response.code == 200
        { success: { status_updated: true } }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
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
        endpoint: "pages/#{read_response.data["page_id"]}",
        secret: process_options[:secret],
        method: "patch",
        body:
      }
    end

    def body
      { properties: { read_response.data["property"] => { select: { name: READY_STATE } } } }
    end
  end
end
