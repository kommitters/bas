# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"
require_relative "../utils/discord/integration"

module Bot
  ##
  # The Bot::NotifyDiscord class serves as a bot implementation to send messages to a
  # Discord readed from a PostgresDB table.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     read_options: {
  #       connection: {
  #         host: "host",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "pto",
  #       bot_name: "HumanizePto"
  #     },
  #     process_options: {
  #       name: "bot name to be shown on discord",
  #       webhook: "discord webhook"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "host",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "pto",
  #       bot_name: "NotifyDiscord"
  #     }
  #   }
  #
  #   bot = Bot::NotifyDiscord.new(options)
  #   bot.execute
  #
  class NotifyDiscord < Bot::Base
    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options)

      reader.execute
    end

    # process function to execute the Discord utility to send the PTO's notification
    #
    def process(read_response)
      return { success: {} } if read_response.data.nil? || read_response.data["notification"] == ""

      params = build_params(read_response)
      response = Utils::Discord::Integration.execute(params)

      if response.code == 204
        { success: {} }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

    # write function to execute the PostgresDB write component
    #
    def write(process_response)
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def build_params(read_response)
      {
        name: process_options[:name],
        notification: read_response.data["notification"],
        webhook: process_options[:webhook]
      }
    end
  end
end
