# frozen_string_literal: true

require_relative "./base"
require_relative "../read/default"
require_relative "../utils/discord/request"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::FetchImagesFromDiscord class serves as a bot implementation to read images
  # from a any thread of Discord channel.
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
  class FetchImagesFromDiscord < Bot::Base
    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Default.new

      reader.execute
    end

    # Process function to execute the Discord utility to fetch images from a discord channel threads
    #
    def process
      response = Utils::Discord::Request.get_thread_messages(params)

      if !response.nil?
        { success: { results: response } }
      else
        { error: "response is empty" }
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
        channel_id: process_options[:discord_channel],
        secret_token: process_options[:secret_token],
        method: "get",
        body: {}
      }
    end
  end
end
