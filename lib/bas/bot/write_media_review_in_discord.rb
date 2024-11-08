# frozen_string_literal: true

require "json"

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"
require_relative "../utils/discord/request"

module Bot
  ##
  # The Bot::WriteMediaReviewInDiscord class serves as a bot implementation to read from a postgres
  # shared storage images object blocks and send them to a thread of Discord channel
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
  #       db_table: "review_media",
  #       tag: "FormatMediaReview"
  #     },
  #     process_options: {
  #       secret_token: "discord_bot_token"
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
  #       tag: "WriteMediaReviewInDiscord"
  #     }
  #   }
  #
  #   bot = Bot::WriteMediaReviewInDiscord.new(options)
  #   bot.execute
  #
  class WriteMediaReviewInDiscord < Bot::Base
    # process function to execute the Discord utility to send image feedback to a thread of a Discord channel
    #
    def process
      return { success: { review_added: nil } } if unprocessable_response

      response = Utils::Discord::Request.split_paragraphs(params)

      if !response.empty?
        { success: { message_id: read_response.data["message_id"], property: read_response.data["property"] } }
      else
        { error: { message: "Response is empty" } }
      end
    end

    private

    def params
      {
        body: read_response.data["review"],
        secret_token: process_options[:secret_token],
        message_id: read_response.data["message_id"],
        channel_id: read_response.data["channel_id"]
      }
    end
  end
end
