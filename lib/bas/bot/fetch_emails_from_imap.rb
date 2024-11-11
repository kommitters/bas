# frozen_string_literal: true

require_relative "./base"
require_relative "../utils/imap/request"

module Bot
  ##
  # The Bot::FetchEmailsFromImap class serves as a bot implementation to fetch emails from a imap server
  # and write them on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   write_options = {
  #     connection:,
  #     db_table: "support_emails",
  #     tag: "FetchEmailsFromImap"
  #   }
  #
  #   params = {
  #     refresh_token: "email server refresh token",
  #     client_id: "email server client it",
  #     client_secret: "email server client secret",
  #     token_uri: "email server refresh token uri",
  #     email_domain: "email server domain",
  #     email_port: "email server port",
  #     user_email: "email to be access",
  #     search_email: "email to be search",
  #     inbox: "inbox to be search"
  #   }
  #
  #   shared_storage_reader = SharedStorage::Default.new
  #   shared_storage_writer = SharedStorage::Postgres.new({ write_options: })
  #
  #   Bot::FetchEmailsFromImap.new(params, shared_storage_reader, shared_storage_writer).execute
  #
  class FetchEmailsFromImap < Bot::Base
    # Process function to request email from an imap server using the imap utility
    #
    def process
      response = Utils::Imap::Request.new(process_options, query).execute

      if response[:error]
        { error: response }
      else
        emails = normalize_response(response[:emails])

        { success: { emails: } }
      end
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
