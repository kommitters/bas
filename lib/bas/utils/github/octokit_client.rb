# frozen_string_literal: true

require "octokit"
require "openssl"
require "jwt"

module Utils
  module Github
    ##
    # This module is a Github utility for making requests to the Github API using the octokit module
    #
    class OctokitClient
      def initialize(params)
        @params = params
      end

      # Build the octokit client using a Github app access token
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

        installation_id = app.find_organization_installation(@params[:organization]).id

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
