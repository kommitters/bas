# frozen_string_literal: true

require "json"

require_relative "./base"
require_relative "../read/postgres"
require_relative "../utils/notion/request"
require_relative "../utils/notion/types"
require_relative "../write/postgres"

module Bot
  class CreateWorkItem < Bot::Base
    include Utils::Notion::Types

    UPDATE_REQUEST = "UpdateWorkItemRequest"

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # process function to execute the Notion utility to send formated blocks to a page
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

    def properties
      {
        "Responsible domain": select(process_options[:domain]),
        "Github Issue id": rich_text(read_response.data["issue"]["id"].to_s),
        "Status": status(process_options[:status]),
        "Detail": title(read_response.data["issue"]["title"])
      }.merge(work_item_type)
    end

    def work_item_type
      case process_options[:work_item_type]
      when "activity" then { "Activity": relation(process_options[:activity]) }
      when "project" then { "Project": relation(process_options[:project]) }
      else {}
      end
    end

    def tag
      return write_options[:tag] if process_response[:success][:notion_wi].nil?

      UPDATE_REQUEST
    end
  end
end
