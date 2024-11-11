# frozen_string_literal: true

require "httparty"

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"
require_relative "../utils/openai/run_assistant"

module Bot
  ##
  # The Bot::ReviewDomainAvailability class serves as a bot implementation to read from a postgres
  # shared storage a domain requests and review its availability.
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
  #       db_table: "web_availability",
  #       tag: "ReviewDomainRequest"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "web_availability",
  #       tag: "ReviewDomainAvailability"
  #     }
  #   }
  #
  #   bot = Bot::ReviewDomainAvailability.new(options)
  #   bot.execute
  #
  class ReviewDomainAvailability < Bot::Base
    # process function to make a http request to the domain and check the status
    #
    def process
      return { success: { review: nil } } if unprocessable_response

      read_response.data["urls"].each do |url_obj|
        url = url_obj["url"]
        response = availability(url)

        response.is_a?(Hash) ? write_invalid_response(response, url) : manage_response(response)
      end

      { success: { review: :ok } }
    end

    private

    def conditions
      {
        where: "archived=$1 AND tag=$2 AND stage=$3 ORDER BY inserted_at ASC",
        params: [false, read_options[:tag], "unprocessed"]
      }
    end

    def availability(url)
      HTTParty.get(url)
    rescue StandardError => e
      { error: e.message }
    end

    def manage_response(response)
      response.code == 200 ? write_ok_response(response) : write_error_response(response)
    end

    def write_ok_response(response)
      logs = request_log(response)
      write_data = { success: { notification: :ok, logs:, url: response.request.uri } }
      Write::Postgres.new(process_options, write_data).execute
    end

    def write_error_response(response)
      notification = notification(response)
      logs = request_log(response)

      write_data = { success: { notification:, logs:, url: response.request.uri } }

      Write::Postgres.new(process_options, write_data).execute
    end

    def write_invalid_response(response, url)
      notification = invalid_notifiction(url, response[:error])
      write_data = { success: { notification:, logs: response[:error], url: } }
      Write::Postgres.new(process_options, write_data).execute
    end

    def request_log(response)
      {
        headers: response.headers.inspect,
        request: response.request.inspect,
        response: response.response.inspect
      }
    end

    def notification(response)
      "⚠️ The Domain #{response.request.uri} is down with an error code of #{response.code}"
    end

    def invalid_notifiction(url, reason)
      "⚠️ The Domain #{url} is down: #{reason}"
    end
  end
end
