# frozen_string_literal: true

require "json"

require_relative "./base"
require_relative "../read/postgres"
require_relative "../utils/notion/request"
require_relative "../utils/notion/update_db_state"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::VerifyIssueExistanceInNotion class serves as a bot implementation to verify if a
  # GitHub issue was already created on a notion database base on a column with the issue id.
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
  #       tag: "GithubIssueRequest"
  #     },
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
  #       db_table: "github_issues",
  #       tag: "VerifyIssueExistanceInNotio"
  #     }
  #   }
  #
  #   bot = Bot::VerifyIssueExistanceInNotion.new(options)
  #   bot.execute
  #
  class VerifyIssueExistanceInNotion < Bot::Base
    NOT_FOUND = "not found"
    NOTION_PROPERTY = "Github Issue Id"

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # process function to execute the Notion utility to verify GitHub issues existance
    # on a notion database
    #
    def process
      return { success: { issue: nil } } if unprocessable_response

      response = Utils::Notion::Request.execute(params)

      if response.code == 200
        result = response.parsed_response["results"].first

        { success: read_response.data.merge({ notion_wi: notion_wi_id(result) }) }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

    # write function to execute the PostgresDB write component
    #
    def write
      options = write_options.merge({ tag: })

      write = Write::Postgres.new(options, process_response)

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
        endpoint: "databases/#{process_options[:database_id]}/query",
        secret: process_options[:secret],
        method: "post",
        body:
      }
    end

    def body
      {
        filter: {
          property: NOTION_PROPERTY,
          rich_text: { equals: read_response.data["issue"]["id"].to_s }
        }
      }
    end

    def notion_wi_id(result)
      return NOT_FOUND if result.nil?

      result["id"]
    end

    def tag
      issue = process_response[:success]

      return write_options[:tag] if issue.nil? || issue[:notion_wi].nil?

      issue[:notion_wi].eql?(NOT_FOUND) ? "CreateWorkItemRequest" : "UpdateWorkItemRequest"
    end
  end
end
