# frozen_string_literal: true

require "json"
require "uri"
require "httparty"
require "time"

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
      def self.execute(params)
        url = URI.parse("#{DISCORD_BASE_URL}/#{params[:endpoint]}")
        headers = headers(params[:secret_token])
        response = HTTParty.send(params[:method], url, { headers: })
        JSON.parse(response.body)
      end

      def self.get_thread_messages(params)
        recent_messages = []
        current_time = Time.now
        messages = execute(params)
        thread_ids = messages.select { |msg| msg["type"] == 18 }.map { |msg| msg["id"] }

        return if thread_ids.empty?

        thread_ids.each do |thread_id|
          thread_messages = get_threads(thread_id, params)

          thread_messages.each do |message|
            message_time = Time.parse(message["timestamp"])

            next unless (current_time - message_time) < 60 && message["attachments"]

            images_urls = message["attachments"].map { |attachment| attachment["url"] }

            next if images_urls.empty?

            recent_messages << {
              "media" => images_urls,
              "thread_id" => thread_id,
              "author" => message["author"]["username"],
              "timestamp" => message["timestamp"],
              "property" => "images"
            }
          end
        end
        recent_messages
      end

      def self.get_threads(thread_id, params)
        url = URI.parse("#{DISCORD_BASE_URL}/channels/#{thread_id}/messages")
        headers = headers(params[:secret_token])
        HTTParty.get(url, { headers: })
      end

      def self.write_media_text(params)
        url = URI.parse("#{DISCORD_BASE_URL}/#{params[:endpoint]}")
        headers = headers(params[:secret_token])
        HTTParty.send(params[:method], url, { body: params[:body].to_json, headers: })
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
