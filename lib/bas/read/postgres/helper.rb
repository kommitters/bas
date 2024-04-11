# frozen_string_literal: true

module Read
  module Postgres
    ##
    # Provides common fuctionalities along the Postgres domain.
    #
    module Helper
      def self.validate_response(response)
        response.response.check_result

        response
      end
    end
  end
end
