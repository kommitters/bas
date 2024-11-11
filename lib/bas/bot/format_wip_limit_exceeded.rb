# frozen_string_literal: true

require_relative "./base"

module Bot
  ##
  # The Bot::FormatWipLimitExceeded class serves as a bot implementation to read exceeded domain wip
  # counts by limits from a PostgresDB database, format them with a specific template, and write them
  # on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   read_options = {
  #     connection:,
  #     db_table: "wip_limits",
  #     tag: "CompareWipLimitCount"
  #   }
  #
  #   write_options = {
  #     connection:,
  #     db_table: "wip_limits",
  #     tag: "FormatWipLimitExceeded"
  #   }
  #
  #   options = {
  #     template: ":warning: The <domain> WIP limit was exceeded by <exceeded>"
  #   }
  #
  #   shared_storage = SharedStorage::Postgres.new({ read_options:, write_options: })
  #
  #   Bot::FormatWipLimitExceeded.new(options, shared_storage).execute
  #
  class FormatWipLimitExceeded < Bot::Base
    WIP_LIMIT_ATTRIBUTES = %w[domain exceeded].freeze

    # Process function to format the notification using a template
    #
    def process
      return { success: { notification: "" } } if unprocessable_response

      exceeded_limits_list = read_response.data["exceeded_domain_count"]

      notification = exceeded_limits_list.reduce("") do |payload, exceeded_limit|
        "#{payload} #{build_template(WIP_LIMIT_ATTRIBUTES, exceeded_limit)} \n"
      end

      { success: { notification: } }
    end

    private

    def build_template(attributes, instance)
      template = process_options[:template]

      attributes.reduce(template) do |formatted_template, attribute|
        formatted_template.gsub("<#{attribute}>", instance[attribute].to_s)
      end
    end
  end
end
