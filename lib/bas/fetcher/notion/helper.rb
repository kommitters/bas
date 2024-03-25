# frozen_string_literal: true

module Fetcher
  module Notion
    ##
    # Provides common fuctionalities along the Notion domain.
    #
    module Helper
      def self.validate_response(response)
        case response.status_code
        when 401
          raise Exceptions::Notion::InvalidApiKey, response.message
        when 404
          raise Exceptions::Notion::InvalidDatabaseId, response.message
        else
          response
        end
      end
    end
  end
end
