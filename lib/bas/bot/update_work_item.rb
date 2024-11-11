# frozen_string_literal: true

require "json"
require "md_to_notion"

require_relative "./base"
require_relative "../read/postgres"
require_relative "../utils/notion/request"
require_relative "../utils/notion/types"
require_relative "../utils/notion/delete_page_blocks"
require_relative "../utils/notion/fetch_database_record"
require_relative "../utils/notion/update_db_page"
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
    GITHUB_COLUMN = "Username"

    # process function to execute the Notion utility to update work items on a notion
    # database
    def process
      return { success: { updated: nil } } if unprocessable_response

      response = process_wi

      if response.code == 200
        update_assigness

        { success: { issue: read_response.data["issue"] } }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

    private

    def process_wi
      delete_wi

      Utils::Notion::Request.execute(params)
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
      options = {
        page_id: read_response.data["notion_wi"],
        secret: process_options[:secret]
      }

      Utils::Notion::DeletePageBlocks.new(options).execute
    end

    def update_assigness
      relation = users.map { |user| user_id(user) }

      options = {
        page_id: read_response.data["notion_wi"],
        secret: process_options[:secret],
        body: { properties: { People: { relation: } }.merge(status) }
      }

      Utils::Notion::UpdateDatabasePage.new(options).execute
    end

    def users
      options = {
        database_id: process_options[:users_database_id],
        secret: process_options[:secret],
        body: { filter: { or: github_usernames } }
      }

      Utils::Notion::FetchDatabaseRecord.new(options).execute
    end

    def github_usernames
      read_response.data["issue"]["assignees"].map do |username|
        { property: GITHUB_COLUMN, rich_text: { equals: username } }
      end
    end

    def user_id(user)
      relation = user.dig("properties", "People", "relation")

      relation.nil? ? {} : relation.first
    end

    def status
      return {} unless read_response.data["issue"]["state"] == "closed"

      { Status: { status: { name: "Done" } } }
    end
  end
end
