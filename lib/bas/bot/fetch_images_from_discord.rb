# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../utils/discord/request"

module Bot
  ##
  # The Bot::FetchMediaFromNotion class serves as a bot implementation to read media (text or images)
  # from a notion database and write them on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     process_options: {
  #       secret_token: "discord_bot_token"
  #       discord_channel: "discord_channel_id"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "review_media",
  #       tag: "FetchImagesFromDiscord"
  #     }
  #   }
  #
  #   bot = Bot::FetchImagesFromDiscord.new(options)
  #   bot.execute
  #
  class FetchImagesFromDiscord < Bot::Base # rubocop:disable Metrics/ClassLength

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Default.new

      reader.execute
    end

    # Process function to execute the Notion utility to fetch media from a notion database
    #
    def process
      response = Utils::Discord::Request.get_recent_thread_messages(recent_messages)

      if response.code == 200
        ## WIP: to verify
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

    # Write function to execute the PostgresDB write component
    #
    def write
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def params
      {
        endpoint: "channels/#{process_options[:discord_channel]}/messages",
        channel_id: process_options[:secret_token]
        secret_token: process_options[:secret_token],
        body: {}
      }
    end
  end
end
