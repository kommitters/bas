# frozen_string_literal: true

module Fetcher
  module Postgres
    module Types
      ##
      # Represents a response received from the Postgres API. It encapsulates essential information about the response,
      # providing a structured way to handle and analyze it's responses.
      class Response
        attr_reader :status, :message, :response, :fields, :records

        SUCCESS_STATUS = "PGRES_TUPLES_OK"

        def initialize(response)
          if response.res_status == SUCCESS_STATUS
            success_response(response)
          else
            failure_response(response)
          end
        end

        private

        def success_response(response)
          @status = response.res_status
          @message = "success"
          @response = response
          @fields = response.fields
          @records = response.values
        end

        def failure_response(response)
          @status = response.res_status
          @message = response.result_error_message
          @response = response
          @fields = nil
          @records = nil
        end
      end
    end
  end
end
