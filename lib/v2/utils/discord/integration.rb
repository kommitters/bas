# frozen_string_literal: true

require "httparty"

module Utils
  module Discord
    module Integration
      def self.execute(params)
        HTTParty.post(params[:webhook], { body: body(params), headers: })
      end

      def self.body(params)
        {
          username: params[:name],
          content: params[:notification]
        }.to_json
      end

      def self.headers
        { "Content-Type" => "application/json" }
      end
    end
  end
end
