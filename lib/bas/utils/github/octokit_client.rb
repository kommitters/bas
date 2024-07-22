# frozen_string_literal: true

require "octokit"
require "openssl"
require "jwt"

module Utils
  module Github
    ##
    # This module is a Imap utility for request emails from an Imap server
    #
    class OctokitClient
      def initialize(params)
        @params = params
      end

      # Execute the imap requets after authenticate the email with the credentials
      #
      def execute
        { client: octokit }
      rescue StandardError => e
        { error: e.to_s }
      end

      private

      def octokit
        Octokit::Client.new(bearer_token: access_token)
      end

      def access_token
        app = Octokit::Client.new(client_id: @params[:app_id], bearer_token: jwt)

        installation_id = app.find_organization_installation("FGSoffice").id

        app.create_app_installation_access_token(installation_id)[:token]
      end

      def jwt
        private_key = OpenSSL::PKey::RSA.new(@params[:private_pem])

        JWT.encode(jwt_payload, private_key, "RS256")
      end

      def jwt_payload
        {
          iat: Time.now.to_i - 60,
          exp: Time.now.to_i + (10 * 60),
          iss: @params[:app_id]
        }
      end
    end
  end
end
