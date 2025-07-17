# frozen_string_literal: true

require "faraday"
require "json"
require_relative "base_operaton_client"

module Utils
  module Operaton
    ##
    # Client for interacting with Operaton's External Task API.
    #
    # This client provides methods to manage external task lifecycle including:
    # - Fetching and locking tasks
    # - Completing tasks with variables
    # - Unlocking tasks
    # - Reporting task failures
    #
    # @example
    #   client = Utils::Operaton::ExternalTaskClient.new(base_url: "https://api.operaton.com", worker_id: "worker-123")
    #   tasks = client.fetch_and_lock("my-topic")
    #
    class ExternalTaskClient < BaseClient
      def initialize(params)
        @worker_id = params[:worker_id]
        validate_params!(params)
        super(
          base_url: params[:base_url],
          username: params[:username],
          password: params[:password]
        )
      end

      def fetch_and_lock(topics_str, lock_duration: 10_000, max_tasks: 1, use_priority: true, variables: [])
        post(
          "/external-task/fetchAndLock",
          {
            workerId: @worker_id,
            maxTasks: max_tasks,
            usePriority: use_priority,
            topics: build_topics_payload(topics_str, lock_duration, variables)
          }
        )
      end

      def complete(task_id, variables = {})
        post(
          "/external-task/#{task_id}/complete",
          {
            workerId: @worker_id,
            variables: format_variables(variables)
          }
        )
      end

      def get_variables(task_id)
        get("/external-task/#{task_id}/variables")
      end

      def unlock(task_id)
        post("/external-task/#{task_id}/unlock")
      end

      def report_failure(task_id, error_message:, error_details:, retries:, retry_timeout:)
        post(
          "/external-task/#{task_id}/failure",
          {
            workerId: @worker_id,
            errorMessage: error_message,
            errorDetails: error_details,
            retries: retries,
            retryTimeout: retry_timeout
          }
        )
      end

      private

      def validate_params!(params)
        raise ArgumentError, "base_url cannot be nil or empty" if params[:base_url].to_s.strip.empty?
        raise ArgumentError, "worker_id cannot be nil or empty" if params[:worker_id].to_s.strip.empty?
      end

      def build_topics_payload(topics_str, lock_duration, variables)
        topic_names = topics_str.is_a?(Array) ? topics_str : topics_str.to_s.split(",")
        topic_names.map do |name|
          {
            topicName: name.strip,
            lockDuration: lock_duration,
            variables: variables
          }
        end
      end
    end
  end
end
