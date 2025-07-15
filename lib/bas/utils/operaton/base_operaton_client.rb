# frozen_string_literal: true

require "faraday"
require "json"

module Utils
  module Operaton
    ##
    # BaseClient provides common HTTP methods and variable formatting logic
    # shared by all Operaton API clients.
    #
    class BaseClient
      def initialize(base_url:)
        raise ArgumentError, "base_url is required" if base_url.to_s.strip.empty?

        @base_url = base_url.chomp("/")
        @conn = build_conn
      end

      private

      def build_conn
        # Override to add multipart support for file uploads and URL encoding for form data
        Faraday.new(url: @base_url) do |f|
          f.request :json
          f.response :json, content_type: /\bjson$/
          f.adapter Faraday.default_adapter
          f.options.timeout = 30
          f.options.open_timeout = 10
        end
      end

      def full_url(path)
        "#{@base_url}#{path.start_with?("/") ? path : "/#{path}"}"
      end

      def get(path, params = {})
        response = @conn.get(full_url(path), params)
        handle_response(response)
      end

      def post(path, body = {}, headers = {})
        response = @conn.post(full_url(path)) do |req|
          req.headers.update(headers) if headers.any?
          req.body = body
        end
        handle_response(response)
      end

      def handle_response(response)
        unless response.success?
          error_body = response.body.is_a?(Hash) ? response.body : { message: response.body }
          raise "Operaton API Error #{response.status}: #{error_body["message"] || error_body}"
        end

        response.body
      end

      def format_variables(vars)
        vars.transform_values do |value|
          {
            value: value,
            type: ruby_type_to_operaton_type(value)
          }
        end
      end

      def ruby_type_to_operaton_type(value)
        case value
        when nil then "Null"
        when String then "String"
        when Integer then "Integer"
        when Float then "Double"
        when TrueClass, FalseClass then "Boolean"
        when Array, Hash then "Json"
        else "Object"
        end
      end
    end
  end
end
