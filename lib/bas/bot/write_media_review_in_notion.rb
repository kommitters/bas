# frozen_string_literal: true

require "json"

require_relative "./base"
require_relative "../read/postgres"
require_relative "../utils/notion/request"
require_relative "../utils/notion/update_db_state"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::WriteMediaReviewInNotion class serves as a bot implementation to read from a postgres
  # shared storage formated notion blocks and send them to a Notion page
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
  #       tag: "FormatMediaReview"
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
  #       tag: "WriteMediaReviewInNotion"
  #     }
  #   }
  #
  #   bot = Bot::WriteMediaReviewInNotion.new(options)
  #   bot.execute
  #
  class WriteMediaReviewInNotion < Bot::Base
    READY_STATE = "ready"

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # process function to execute the Notion utility to send formated blocks to a page
    #
    def process
      return { success: { review_added: nil } } if unprocessable_response

      response = Utils::Notion::Request.execute(params)

      if response.code == 200
        update_state

        { success: { page_id: read_response.data["page_id"], property: read_response.data["property"] } }
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
        endpoint: "blocks/#{read_response.data["page_id"]}/children",
        secret: process_options[:secret],
        method: "patch",
        body:
      }
    end

    def body
      { children: [{ object: "block", type: "toggle", toggle: }] }
    end

    def toggle
      {
        rich_text: [{ type: "text", text: { content: toggle_title } }, mention],
        children: toggle_childrens
      }
    end

    def toggle_childrens
      JSON.parse(read_response.data["review"])
    end

    def mention
      {
        type: "mention",
        mention: {
          type: "user",
          user: { id: read_response.data["created_by"] }
        }
      }
    end

    def toggle_title
      case read_response.data["media_type"]
      when "images" then "Image review results/"
      when "paragraph" then "Text review results/"
      end
    end

    def update_state
      data = {
        property: read_response.data["property"],
        page_id: read_response.data["page_id"],
        state: READY_STATE,
        secret: process_options[:secret]
      }

      Utils::Notion::UpdateDbState.execute(data)
    end
  end
end
