# frozen_string_literal: true

require_relative "./base"
require_relative "../utils/digital_ocean/request"

module Bot
  ##
  # The Bot::FetchBillingFromDigitalOcean class serves as a bot implementation to read digital
  # ocean current billing using the DigitalOcean API
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     process_options: {
  #       secret: "digital_ocean_secret_key"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "host",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "use_cases",
  #       tag: "FetchBillingFromDigitalOcean"
  #     }
  #   }
  #
  #   bot = Bot::FetchBillingFromDigitalOcean.new(options)
  #   bot.execute
  #
  class FetchBillingFromDigitalOcean < Bot::Base
    # Process function to execute the DigitalOcean utility to fetch bills
    #
    def process
      response = Utils::DigitalOcean::Request.execute(params)

      if response.code == 200
        { success: { billing: response.parsed_response, last_billing: } }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

    private

    def params
      {
        endpoint: "customers/my/balance",
        secret: process_options[:secret],
        method: "get",
        body: {}
      }
    end

    def last_billing
      read_response.data.nil? ? nil : read_response.data["billing"]
    end
  end
end
