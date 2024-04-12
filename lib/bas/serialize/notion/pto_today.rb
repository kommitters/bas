# frozen_string_literal: true

require_relative "../../domain/pto"
require_relative "../base"

module Serialize
  module Notion
    ##
    # This class implements the methods of the Serialize::Base module, specifically designed for preparing or
    # shaping PTO's data coming from a Read::Base implementation.
    #
    class PtoToday
      include Base

      PTO_PARAMS = ["Description", "Desde?", "Hasta?"].freeze

      # Implements the logic for shaping the results from a reader response.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Read::Notion::Types::Response</tt> notion_response: Notion response object.
      #
      # <br>
      # <b>returns</b> <tt>List<Domain::Pto></tt> ptos_list, serialized PTO's to be used by a Formatter::Base
      # implementation.
      #
      def execute(notion_response)
        return [] if notion_response.results.empty?

        normalized_notion_data = normalize_response(notion_response.results)

        normalized_notion_data.map do |pto|
          Domain::Pto.new(pto["Description"], pto["Desde?"], pto["Hasta?"])
        end
      end

      private

      def normalize_response(response)
        return [] if response.nil?

        response.map do |value|
          pto_fields = value["properties"].slice(*PTO_PARAMS)

          {
            "Description" => extract_description_field_value(pto_fields["Description"]),
            "Desde?" => extract_date_field_value(pto_fields["Desde?"]),
            "Hasta?" => extract_date_field_value(pto_fields["Hasta?"])
          }
        end
      end

      def extract_description_field_value(data)
        names = data["title"].map { |name| name["plain_text"] }

        names.join(" ")
      end

      def extract_date_field_value(date)
        {
          from: extract_start_date(date),
          to: extract_end_date(date)
        }
      end

      def extract_start_date(data)
        data["date"]["start"]
      end

      def extract_end_date(data)
        data["date"]["end"]
      end
    end
  end
end
