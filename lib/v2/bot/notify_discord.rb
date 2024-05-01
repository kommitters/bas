# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"
require_relative "../utils/discord/integration"

module Bot
  class NotifyDiscord < Bot::Base
    def read
      reader = Read::Postgres.new(read_options)

      reader.execute
    end

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
