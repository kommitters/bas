# frozen_string_literal: true

require "faraday"
require "json"
require "faraday/multipart"

module Utils
  module Operaton
    ##
    # Client for deploying BPMN processes and starting process instances in Operaton (Camunda 7 API compatible)
    class ProcessClient
      def initialize(base_url:)
        raise ArgumentError, "base_url is required" if base_url.to_s.strip.empty?

        @base_url = base_url.chomp("/")

        @conn = Faraday.new(url: @base_url) do |f|
          f.request :multipart
          f.request :url_encoded
          f.response :json, content_type: /\bjson$/
          f.adapter Faraday.default_adapter
        end
      end

      def deploy_process(file_path, deployment_name:)
        raise "File not found: #{file_path}" unless File.exist?(file_path)

        puts "📁 Attempting to read file: #{file_path}"
        puts "📦 Deployment name: #{deployment_name}"

        payload = {
          "deployment-name" => deployment_name,
          "deploy-changed-only" => "true",
          "data" => Faraday::Multipart::FilePart.new(file_path, "application/octet-stream", File.basename(file_path))
        }

        post("/deployment/create", payload)
      end

      def instance_with_business_key_exists?(process_key, business_key)
        query_params = {
          processDefinitionKey: process_key,
          maxResults: 50
        }

        response = @conn.get(full_url("/history/process-instance"), query_params)

        raise "Error verifying existing instance: #{response.status}" unless response.success?

        response.body.any? { |instance| instance["businessKey"] == business_key }
      end

      def start_process_instance_by_key(process_key, business_key:, variables: {}, validate_business_key: true)
        validate_uniqueness!(process_key, business_key) if validate_business_key

        json_payload = {
          businessKey: business_key,
          variables: format_variables(variables)
        }

        response = @conn.post(full_url("/process-definition/key/#{process_key}/start")) do |req|
          req.headers["Content-Type"] = "application/json"
          req.body = JSON.generate(json_payload)
        end

        handle_response(response)
      end

      private

      def validate_uniqueness!(process_key, business_key)
        return unless instance_with_business_key_exists?(process_key, business_key)

        raise "There is already an instance for processing '#{process_key}' with business key '#{business_key}'"
      end

      def post(path, body = {}, headers = {})
        response = @conn.post(full_url(path)) do |req|
          req.headers.update(headers) if headers.any?
          req.body = body
        end

        raise "Error deploying: #{response.status} - #{response.body}" unless response.success?

        handle_response(response)
      end

      def get(path, params = {})
        response = @conn.get(full_url(path), params)
        handle_response(response)
      end

      def full_url(path)
        "#{@base_url}#{path.start_with?("/") ? path : "/#{path}"}"
      end

      def handle_response(response)
        raise "Operaton API Error #{response.status}: #{response.body}" unless response.success?

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
        when String then "String"
        when Integer then "Integer"
        when Float then "Double"
        when TrueClass, FalseClass then "Boolean"
        else "Object"
        end
      end
    end
  end
end
