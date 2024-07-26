# frozen_string_literal: true

require "json"
require "md_to_notion"

require_relative "./base"
require_relative "../read/postgres"
require_relative "../utils/notion/request"
require_relative "../utils/notion/types"
require_relative "../utils/notion/delete_page_blocks"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::UpdateWorkItem class serves as a bot implementation to update "work items" on a
  # notion database using information of a GitHub issue.
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
  #       db_table: "github_issues",
  #       tag: "UpdateWorkItemRequest"
  #     },
  #     process_options: {
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
  #       db_table: "github_issues",
  #       tag: "UpdateWorkItem"
  #     }
  #   }
  #
  #   bot = Bot::UpdateWorkItem.new(options)
  #   bot.execute
  #
  class UpdateWorkItem < Bot::Base
    include Utils::Notion::Types

    DESCRIPTION = "Issue Description"

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # process function to execute the Notion utility to update work items on a notion
    # database
    def process
      return { success: { updated: nil } } if unprocessable_response

      delete_wi

      response = Utils::Notion::Request.execute(params)

      if response.code == 200
        { success: { issue: read_response.data["issue"] } }
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
        endpoint: "blocks/#{read_response.data["notion_wi"]}/children",
        secret: process_options[:secret],
        method: "patch",
        body:
      }
    end

    def body
      { children: description + [issue_reference] }
    end

    def description
      MdToNotion::Parser.markdown_to_notion_blocks(read_response.data["issue"]["body"])
    end

    def issue_reference
      {
        object: "block",
        type: "paragraph",
        paragraph: rich_text("issue", read_response.data["issue"]["html_url"])
      }
    end

    def delete_wi
      params = {
        page_id: read_response.data["notion_wi"],
        secret: process_options[:secret]
      }

      Utils::Notion::DeletePageBlocks.new(params).execute
    end
  end
end
