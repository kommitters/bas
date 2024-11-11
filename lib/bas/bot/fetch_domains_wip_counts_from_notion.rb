# frozen_string_literal: true

require_relative "./base"
require_relative "../utils/notion/request"

module Bot
  ##
  # The Bot::FetchDomainsWipCountsFromNotion class serves as a bot implementation to fetch work items
  # in progress or in hold from a Notion database, count how many are by domain, and write them on a
  # PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   write_options = {
  #     connection:,
  #     db_table: "wip_limits",
  #     tag: "FetchDomainsWipCountsFromNotion"
  #   }
  #
  #   options = {
  #     database_id: "notion_database_id",
  #     secret: "notion_secret"
  #   }
  #
  #   shared_storage_reader = SharedStorage::Default.new
  #   shared_storage_writer = SharedStorage::Postgres.new({ write_options: })
  #
  #   Bot::FetchDomainsWipCountsFromNotion.new(options, shared_storage_reader, shared_storage_writer).execute
  #
  class FetchDomainsWipCountsFromNotion < Bot::Base
    # Process function to execute the Notion utility to fetch work item from the notion database
    #
    def process
      response = Utils::Notion::Request.execute(params)

      if response.code == 200
        work_items_domains = normalize_response(response.parsed_response["results"])
        domain_wip_count = count_domain_items(work_items_domains)

        { success: { domain_wip_count: } }
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
        body:
      }
    end

    def body
      {
        filter: {
          "and": [
            { property: "OK", formula: { string: { contains: "✅" } } },
            { "or": status_conditions }
          ]
        }
      }
    end

    def status_conditions
      [
        { property: "Status", status: { equals: "In Progress" } },
        { property: "Status", status: { equals: "On Hold" } }
      ]
    end

    def normalize_response(results)
      return [] if results.nil?

      results.map do |pto|
        work_item_fields = pto["properties"]

        {
          "domain" => extract_domain_field_value(work_item_fields["Responsible domain"])
        }
      end
    end

    def extract_domain_field_value(data)
      data["select"]["name"]
    end

    def count_domain_items(work_items_list)
      domain_work_items = work_items_list.group_by { |work_item| work_item["domain"] }

      domain_work_items.transform_values(&:count)
    end
  end
end
