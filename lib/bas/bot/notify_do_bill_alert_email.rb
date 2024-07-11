# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"
require_relative "../utils/google/send_email"

module Bot
  ##
  # The Bot::NotifyDoBillAlertEmail class serves as a bot implementation to send digital
  # ocean daily bill exceeded alert emails to a recipient using a google account
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
  #       db_table: "do_billing",
  #       tag: "FetchBillingFromDigitalOcean"
  #     },
  #     process_options: {
  #       refresh_token: "email server refresh token",
  #       client_id: "email server client it",
  #       client_secret: "email server client secret",
  #       user_email: "sender@mail.com",
  #       recipient_email: "recipient@mail.com",
  #       threshold: "THRESHOLD"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "do_billing",
  #       tag: "NotifyDoBillAlertEmail"
  #     }
  #   }
  #
  #   bot = Bot::NotifyDoBillAlertEmail.new(options)
  #   bot.execute
  #
  class NotifyDoBillAlertEmail < Bot::Base
    SUBJECT = "Digital Ocean Daily Threshold Alert"

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # process function to execute the Google send email utility
    #
    def process
      return { success: {} } if unprocessable_response

      response = Utils::GoogleService::SendEmail.new(params).execute

      response[:error].nil? ? { success: {} } : { error: response }
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
      process_options.merge({ subject: SUBJECT, message: read_response.data["notification"] })
    end
  end
end
