# frozen_string_literal: true

require_relative "./base"
require_relative "../read/default"
require_relative "../utils/imap/request"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::FetchEmailsFromImap class serves as a bot implementation to fetch emails from a imap server
  # and write them on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   params = {
  #     process_options: {
  #       refresh_token: "email server refresh token",
  #       client_id: "email server client it",
  #       client_secret: "email server client secret",
  #       token_uri: "email server refresh token uri",
  #       email_domain: "email server domain",
  #       email_port: "email server port",
  #       user_email: "email to be access",
  #       search_email: "email to be search",
  #       inbox: "inbox to be search"
  #     },
  #     write_options: {
  #       connection:,
  #       db_table: "use_cases",
  #       bot_name: "FetchEmailsFromImap"
  #     }
  #   }
  #
  #   bot = Bot::FetchEmailsFromImap.new(options)
  #   bot.execute
  #
  class FetchEmailsFromImap < Bot::Base
    # Read function to execute the default Read component
    #
    def read
      reader = Read::Default.new

      reader.execute
    end

    # Process function to request email from an imap server using the imap utility
    #
    def process(_read_response)
      response = Utils::Imap::Request.new(process_options, query).execute

      if response[:error]
        { error: response }
      else
        emails = normalize_response(response[:emails])

        { success: { emails: } }
      end
    end

    # Write function to execute the PostgresDB write component
    #
    def write(process_response)
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def query
      yesterday = (Time.now - (60 * 60 * 24)).strftime("%d-%b-%Y")

      ["TO", process_options[:search_email], "SINCE", yesterday]
    end

    def normalize_response(results)
      return [] if results.nil?

      results.map do |value|
        message = value[:message]

        {
          "message_id": value[:message_id],
          "sender" => extract_sender(message),
          "date" => message.date,
          "subject" => message.subject
        }
      end
    end

    def extract_sender(value)
      mailbox = value.sender[0]["mailbox"]
      host = value.sender[0]["host"]

      "#{mailbox}@#{host}"
    end
  end
end
