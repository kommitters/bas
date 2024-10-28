# frozen_string_literal: true

require "json"
require "uri"
require "httparty"

module Utils
  module Discord
    ##
    # This module is a Discord utility for obtain all images of any threads of a
    # Discord channel.
    #
    module Request
      DISCORD_BASE_URL = "https://discord.com/api/v10"

      # Implements the request process logic to Discord.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>method</tt> HTTP request method: post, get, put, etc.
      # * <tt>body</tt> Request body (Hash).
      # * <tt>endpoint</tt> Notion resource endpoint.
      # * <tt>secret_token</tt> Discord Bot Token.
      #
      # <br>
      #
      #

      def self.get_discord_images(message)
        images_urls = message.attachments.map(&:url)

        {
          "media" => images_urls,
          "message_id" => message.id,
          "channel_id" => message.channel.id,
          "author" => message.author.username,
          "timestamp" => message.timestamp.to_s,
          "property" => "images"
        }
      end

      def self.write_media_text(params, combined_paragraphs)
        url_message = URI.parse("#{DISCORD_BASE_URL}/channels/#{params[:channel_id]}/messages")
        headers = headers(params[:secret_token])
        body = { content: combined_paragraphs }.to_json

        HTTParty.post(url_message, { body:, headers: })
      end

      def self.split_paragraphs(params)
        paragraphs = params[:body].split("--DIVISION--").map(&:strip).reject(&:empty?)

        paragraphs.each_slice(2) do |paragraph|
          next if paragraph.empty?

          combined_paragraphs = paragraph.join("\n\n")
          write_media_text(params, combined_paragraphs)
        end
      end

      def self.headers(secret_token)
        {
          "Authorization" => secret_token.to_s,
          "Content-Type" => "application/json"
        }
      end
    end
  end
end
