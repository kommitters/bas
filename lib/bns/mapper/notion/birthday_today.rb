# frozen_string_literal: true

require_relative "../../domain/birthday"
require_relative "../base"

module Mapper
  module Notion
    ##
    # This class implementats the methods of the Mapper::Base module, specifically designed for preparing or
    # shaping birthdays data coming from a Fetcher::Base implementation.
    class BirthdayToday
      include Base

      BIRTHDAY_PARAMS = ["Complete Name", "BD_this_year"].freeze

      # Implements the logic for shaping the results from a fetcher response.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Fetcher::Notion::Types::Response</tt> notion_response: Notion response object.
      #
      # <br>
      # <b>return</b> <tt>List<Domain::Birthday></tt> birthdays_list, mapped birthdays to be used by a
      # Formatter::Base implementation.
      #
      def map(notion_response)
        return [] if notion_response.results.empty?

        normalized_notion_data = normalize_response(notion_response.results)

        normalized_notion_data.map do |birthday|
          Domain::Birthday.new(birthday["Complete Name"], birthday["BD_this_year"])
        end
      end

      private

      def normalize_response(results)
        return [] if results.nil?

        results.map do |value|
          birthday_fields = value["properties"].slice(*BIRTHDAY_PARAMS)

          birthday_fields.each do |field, birthday_value|
            birthday_fields[field] = extract_birthday_value(field, birthday_value)
          end

          birthday_fields
        end
      end

      def extract_birthday_value(field, value)
        case field
        when "Complete Name" then extract_rich_text_field_value(value)
        when "BD_this_year" then extract_date_field_value(value)
        end
      end

      def extract_rich_text_field_value(data)
        data["rich_text"][0]["plain_text"]
      end

      def extract_date_field_value(data)
        data["formula"]["date"]["start"]
      end
    end
  end
end
