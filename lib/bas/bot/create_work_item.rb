# frozen_string_literal: true

require "json"

require_relative "./base"
require_relative "../read/postgres"
require_relative "../utils/notion/request"
require_relative "../utils/notion/types"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::CreateWorkItem class serves as a bot implementation to create "work items" on a
  # notion database using information of a GitHub issue.
  #
  # <br>
  # <b>Example</b>
  #
  #  read_options = {
  #    connection:,
  #    db_table: "github_issues",
  #    tag: "CreateWorkItemRequest"
  #  }
  #
  #  write_options = {
  #    connection:,
  #    db_table: "github_issues",
  #    tag: "CreateWorkItem"
  #  }
  #
  #  options = {
  #    database_id: "notion_database_id",
  #    secret: "notion_secret"
  #  }
  #
  #  shared_storage = SharedStorage::Postgres.new({ read_options:, write_options: })
  #
  #  Bot::CreateWorkItem.new(options, shared_storage).execute
  #
  class CreateWorkItem < Bot::Base
    include Utils::Notion::Types

    UPDATE_REQUEST = "UpdateWorkItemRequest"
    STATUS = "Backlog"

    # process function to execute the Notion utility to create work items on a notion
    # database
    #
    def process
      return { success: { created: nil } } if unprocessable_response

      response = Utils::Notion::Request.execute(params)

      if response.code == 200
        { success: { issue: read_response.data["issue"], notion_wi: response["id"] } }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

    # write function to execute the PostgresDB write component
    #
    def write
      @shared_storage_writer.write_options = @shared_storage_writer.write_options.merge({ tag: })

      @shared_storage_writer.write(process_response)
    end

    private

    def params
      {
        endpoint: "pages",
        secret: process_options[:secret],
        method: "post",
        body:
      }
    end

    def body
      {
        parent: { database_id: process_options[:database_id] },
        properties:
      }
    end

    def properties # rubocop:disable Metrics/AbcSize
      {
        "Responsible domain": select(read_response.data["domain"]),
        "Github Issue Id": rich_text(read_response.data["issue"]["id"].to_s),
        "Status": status(STATUS),
        "Detail": title(read_response.data["issue"]["title"])
      }.merge(work_item_type)
    end

    def work_item_type
      case read_response.data["work_item_type"]
      when "activity" then { "Activity": relation(read_response.data["type_id"]) }
      when "project" then { "Project": relation(read_response.data["type_id"]) }
      else {}
      end
    end

    def tag
      if process_response[:success].nil? || process_response[:success][:notion_wi].nil?
        return @shared_storage_writer.write_options[:tag]
      end

      UPDATE_REQUEST
    end
  end
end
