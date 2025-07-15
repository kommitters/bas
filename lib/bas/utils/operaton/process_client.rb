# frozen_string_literal: true

require "faraday"
require "json"
require "faraday/multipart"
require "logger"
require_relative "base_operaton_client"

module Utils
  module Operaton
    ##
    # Client for deploying BPMN processes and starting process instances in Operaton (Camunda 7 API compatible)
    #
    # @example
    #   client = Utils::Operaton::ProcessClient.new(base_url: "https://api.operaton.com")
    #   tasks = client.deploy_process(file_path, deployment_name: deployment_name)
    #
    class ProcessClient < BaseClient
      def initialize(base_url:)
        @logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)
        super(base_url: base_url)
      end

      def deploy_process(file_path, deployment_name:)
        raise "File not found: #{file_path}" unless File.exist?(file_path)
        raise "File is not readable: #{file_path}" unless File.readable?(file_path)

        @logger.info "📁 Attempting to read file: #{file_path}"
        @logger.info "📦 Deployment name: #{deployment_name}"

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
          maxResults: 50,
          active: true
        }

        response = get("/history/process-instance", query_params)
        response.any? { |instance| instance["businessKey"] == business_key }
      end

      def start_process_instance_by_key(process_key, business_key:, variables: {})
        json_payload = {
          businessKey: business_key,
          variables: format_variables(variables)
        }

        post(
          "/process-definition/key/#{process_key}/start",
          JSON.generate(json_payload),
          { "Content-Type" => "application/json" }
        )
      end

      private

      def build_conn
        Faraday.new(url: @base_url) do |f|
          f.request :multipart
          f.request :url_encoded
          f.response :json, content_type: /\bjson$/
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end
