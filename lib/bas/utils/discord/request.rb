# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Utils
  module Discord
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

        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(url.request_uri)
        request['Authorization'] = "Bot #{params[:secret_token]}"

        response = http.request(request)
        JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
      end

      def self.get_recent_thread_messages(channel_id, secret_token)
        recent_messages = {}
        current_time = Time.now

        messages = execute(channel_id, secret_token)

        thread_ids = messages.select { |msg| msg['type'] == 18 }.map { |msg| msg['id'] }

        thread_ids.each do |thread_id|
          thread_messages = execute(thread_id, secret_token)

          thread_messages.each do |message|
            message_time = Time.parse(message['timestamp'])
            if (current_time - message_time) < 60 && !message['content'].nil?
              attachment = message["attachments"].first
              recent_messages[message['id']] = {
                filename: attachment['filename'],
                url: attachment['url'],
                author: message['author']['username'],
                timestamp: message['timestamp']
              }
            end
          end
        end

        recent_messages
      end
    end
  end
end
