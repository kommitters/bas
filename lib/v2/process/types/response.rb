# frozen_string_literal: true

module Process
  module Types
    class Response
      attr_reader :data

      def initialize(response = {})
        @data = response
      end
    end
  end
end
