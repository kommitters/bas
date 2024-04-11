# frozen_string_literal: true

require "octokit"
require "openssl"
require "jwt"

require_relative "../base"
require_relative "./types/response"

module Read
  module Github
    ##
    # This class is an implementation of the Read::Base interface, specifically designed
    # for reading data from a GitHub repository.
    #
    class Base < Read::Base
      protected

      # Implements the data reading logic to get data from a Github repository.
      # It connects to Github using the octokit gem, authenticates with a github app,
      # request the data and returns a validated response.
      #
      def read(method, *filter)
        octokit_response = octokit.public_send(method, *filter)

        Read::Github::Types::Response.new(octokit_response)
      end

      private

      def octokit
        Octokit::Client.new(bearer_token: access_token)
      end

      def access_token
        app = Octokit::Client.new(client_id: config[:app_id], bearer_token: jwt)

        app.create_app_installation_access_token(config[:installation_id])[:token]
      end

      def jwt
        private_pem = File.read(config[:secret_path])
        private_key = OpenSSL::PKey::RSA.new(private_pem)

        JWT.encode(jwt_payload, private_key, "RS256")
      end

      def jwt_payload
        {
          iat: Time.now.to_i - 60,
          exp: Time.now.to_i + (10 * 60),
          iss: config[:app_id]
        }
      end
    end
  end
end
