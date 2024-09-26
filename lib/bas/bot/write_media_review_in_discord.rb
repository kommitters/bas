# frozen_string_literal: true

require "json"

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::WriteMediaReviewInNotion class serves as a bot implementation to read from a postgres
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
    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # process function to execute the Discord utility to send image feedback to a thread of Discord channel
    #
    def process
      return { success: { review_added: nil } } if unprocessable_response

      response = Utils::Discord::Request.write_media_text(params)

      if !response.nil?
        { success: { thread_id: read_response.data["thread_id"], property: read_response.data["property"] } }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

    # write function to execute the PostgresDB write component
    #
    def write
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def conditions
      {
        where: "archived=$1 AND tag=$2 AND stage=$3 ORDER BY inserted_at ASC",
        params: [false, read_options[:tag], "unprocessed"]
      }
    end

    def params
      {
        endpoint: "channels/#{read_response.data["thread_id"]}/messages",
        secret_token: process_options[:secret_token],
        method: "post",
        body:
      }
    end

    def body
      { content: "#{toggle_title}\n\n#{read_response.data["review"]}\n\n#{mention_content}" }
    end

    def mention_content
      author_name = read_response.data["author"]
      "<@#{author_name}>"
    end

    def toggle_title
      case read_response.data["media_type"]
      when "images" then "Image review results"
      when "paragraph" then "Text review results"
      end
    end
  end
end
