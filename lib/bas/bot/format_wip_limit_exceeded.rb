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
  #   options = {
  #     read_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "use_cases",
  #       tag: "CompareWipLimitCount"
  #     },
  #     process_options: {
  #       template: "exceeded wip limit template message"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "use_cases",
  #       tag: "FormatWipLimitExceeded"
  #     }
  #   }
  #
  #   bot = Bot::FormatWipLimitExceeded.new(options)
  #   bot.execute
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
