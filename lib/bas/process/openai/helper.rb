# frozen_string_literal: true

module Process
  module OpenAI
    ##
    # Provides common fuctionalities along the Process::OpenAI domain.
    #
    module Helper
      def self.validate_response(response)
        case response.status_code
        when 200
          response
        else
          raise StandardError, response.message
        end
      end
    end
  end
end
