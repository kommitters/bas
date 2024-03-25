# frozen_string_literal: true

require_relative "../../domain/pto"
require_relative "../base"

module Mapper
  module Notion
    ##
    # This class implementats the methods of the Mapper::Base module, specifically designed for preparing or
    # shaping PTO's data coming from a Fetcher::Base implementation.
    #
    class PtoToday
      include Base

      PTO_PARAMS = ["Person", "Desde?", "Hasta?"].freeze

      # Implements the logic for shaping the results from a fetcher response.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Fetcher::Notion::Types::Response</tt> notion_response: Notion response object.
      #
      # <br>
      # <b>returns</b> <tt>List<Domain::Pto></tt> ptos_list, mapped PTO's to be used by a Formatter::Base
      # implementation.
      #
      def map(notion_response)
        return [] if notion_response.results.empty?

        normalized_notion_data = normalize_response(notion_response.results)

        normalized_notion_data.map do |pto|
          Domain::Pto.new(pto["Person"], pto["Desde?"], pto["Hasta?"])
        end
      end

      private

      def normalize_response(response)
        return [] if response.nil?

        response.map do |value|
          pto_fields = value["properties"].slice(*PTO_PARAMS)

          pto_fields.each do |field, pto_value|
            pto_fields[field] = extract_pto_value(field, pto_value)
          end

          pto_fields
        end
      end

      def extract_pto_value(field, value)
        case field
        when "Person" then extract_person_field_value(value)
        when "Desde?" then extract_date_field_value(value)
        when "Hasta?" then extract_date_field_value(value)
        end
      end

      def extract_person_field_value(data)
        data["people"][0]["name"]
      end

      def extract_date_field_value(data)
        data["date"]["start"]
      end
    end
  end
end
