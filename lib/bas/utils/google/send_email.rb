# frozen_string_literal: true

require "google/apis/gmail_v1"
require "googleauth"

module Utils
  module GoogleService
    ##
    # This module is a Google service utility to send emails from a google account
    #
    class SendEmail
      SCOPES = ["https://mail.google.com/", "https://www.googleapis.com/auth/gmail.send"].freeze
      CONTENT_TYPE = "message/rfc822"

      def initialize(params)
        @refresh_token = params[:refresh_token]
        @client_id = params[:client_id]
        @client_secret = params[:client_secret]
        @user_email = params[:user_email]
        @recipient_email = params[:recipient_email]
        @subject = params[:subject]
        @message = params[:message]
      end

      def execute
        { send_email: }
      rescue StandardError => e
        { error: e.to_s }
      end

      private

      def send_email
        service = Google::Apis::GmailV1::GmailService.new

        service.authorization = access_token

        service.send_user_message(@user_email, upload_source:, content_type: CONTENT_TYPE)
      end

      def upload_source
        message = <<~END_OF_MESSAGE
          From: me
          To: #{@recipient_email.join(",")}
          Subject: #{@subject}
          MIME-Version: 1.0
          Content-Type: text/plain; charset=UTF-8

          #{@message}
        END_OF_MESSAGE

        StringIO.new(message)
      end

      def access_token
        client = Google::Auth::UserRefreshCredentials.new(auth_params)

        client.fetch_access_token!
        client.access_token
      end

      def auth_params
        {
          client_id: @client_id,
          client_secret: @client_secret,
          refresh_token: @refresh_token,
          scope: SCOPES
        }
      end
    end
  end
end
