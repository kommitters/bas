# frozen_string_literal: true

require_relative "../../domain/work_items_limit"
require_relative "../base"

module Serialize
  module Notion
    ##
    # This class implementats the methods of the Serialize::Base module, specifically designed
    # for preparing or shaping work items data coming from a Read::Base implementation.
    class WorkItemsLimit
      include Base

      WORK_ITEM_PARAMS = ["Responsible domain"].freeze

      # Implements the logic for shaping the results from a reader response.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Read::Notion::Types::Response</tt> notion_response: Notion response object.
      #
      # <br>
      # <b>return</b> <tt>List<Domain::WorkItem></tt> work_items_list, serialized work items to be used by a
      # Formatter::Base implementation.
      #
      def execute(notion_response)
        return [] if notion_response.results.empty?

        normalized_notion_data = normalize_response(notion_response.results)

        domain_items_count = count_domain_items(normalized_notion_data)

        domain_items_count.map do |domain, items_count|
          Domain::WorkItemsLimit.new(domain, items_count)
        end
      end

      private

      def normalize_response(results)
        return [] if results.nil?

        results.map do |value|
          work_item_fields = value["properties"].slice(*WORK_ITEM_PARAMS)

          work_item_fields.each do |field, work_item_value|
            work_item_fields[field] = extract_domain_field_value(work_item_value)
          end

          work_item_fields
        end
      end

      def extract_domain_field_value(data)
        data["select"]["name"]
      end

      def count_domain_items(work_items_list)
        domain_work_items = work_items_list.group_by { |work_item| work_item["Responsible domain"] }

        domain_work_items.transform_values(&:count)
      end
    end
  end
end
