# frozen_string_literal: true

require_relative "./base"
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
  #       tag: "HumanizePto"
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
  #       tag: "NotifyDiscord"
  #     }
  #   }
  #
  #   bot = Bot::NotifyDiscord.new(options)
  #   bot.execute
  #
  class NotifyDiscord < Bot::Base
    # process function to execute the Discord utility to send the PTO's notification
    #
    def process
      return { success: {} } if unprocessable_response

      response = Utils::Discord::Integration.execute(params)

      if response.code == 204
        { success: {} }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

    private

    def params
      {
        name: process_options[:name],
        notification: read_response.data["notification"],
        webhook: process_options[:webhook]
      }
    end
  end
end
