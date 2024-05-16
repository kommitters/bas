# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"

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
  #       bot_name: "CompareWipLimitCount"
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
  #       bot_name: "FormatWipLimitExceeded"
  #     }
  #   }
  #
  #   bot = Bot::FormatWipLimitExceeded.new(options)
  #   bot.execute
  #
  class FormatWipLimitExceeded < Bot::Base
    WIP_LIMIT_ATTRIBUTES = %w[domain exceeded].freeze

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options)

      reader.execute
    end

    # Process function to format the notification using a template
    #
    def process(read_response)
      return { success: { notification: "" } } if unprocessable_response(read_response.data)

      exceedded_limits_list = read_response.data["exceeded_domain_count"]

      notification = exceedded_limits_list.reduce("") do |payload, exceedded_limit|
        "#{payload} #{build_template(WIP_LIMIT_ATTRIBUTES, exceedded_limit)} \n"
      end

      { success: { notification: } }
    end

    # Write function to execute the PostgresDB write component
    #
    def write(process_response)
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def unprocessable_response(read_data)
      read_data.nil? || read_data["exceeded_domain_count"] == {}
    end

    def build_template(attributes, instance)
      template = process_options[:template]

      attributes.reduce(template) do |formated_template, attribute|
        formated_template.gsub("<#{attribute}>", instance[attribute].to_s)
      end
    end
  end
end