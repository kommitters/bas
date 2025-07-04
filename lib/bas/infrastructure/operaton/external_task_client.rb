# frozen_string_literal: true

require "faraday"
require "json"

module Bas
    module Infrastructure
        module Operaton
            class ExternalTaskClient
            def initialize(base_url:, worker_id:)
                @base_url = base_url
                @worker_id = worker_id

                @conn = Faraday.new(url: base_url) do |f|
                f.request :json # Convert hashes in Ruby to JSON
                f.response :json, content_type: /\bjson$/ # Parse JSON responses to hashes in Ruby
                f.adapter Faraday.default_adapter # Use the default adapter (Net::HTTP)
                end
            end

            def fetch_and_lock(topic_name, lock_duration: 10_000, max_tasks: 1, userPriority: true, variables: [])
                post("/external-task/fetchAndLock", {
                workerId: @worker_id,
                maxTasks: max_tasks,
                userPriority: userPriority,
                topics: [
                    {
                    topicName: topic_name,
                    lockDuration: lock_duration,
                    variables: variables
                    }
                ]
                })
            end

            def complete(task_id, variables = {})
                post("/external-task/#{task_id}/complete", {
                workerId: @worker_id,
                variables: format_variables(variables)
                })
            end

            def get_variables(task_id)
                get("/external-task/#{task_id}/variables")
            end

            def unlock(task_id)
                post("/external-task/#{task_id}/unlock")
            end

            def report_failure(task_id, error_message:, error_details:, retries:, retry_timeout:)
                post("/external-task/#{task_id}/failure", {
                workerId: @worker_id,
                errorMessage: error_message,
                errorDetails: error_details,
                retries: retries,
                retryTimeout: retry_timeout
                })
            end

            private

            def fullUrl(path)
                "#{@base_url}#{path}"
            end

            def post(path, body = {})
                handle_response(@conn.post(fullUrl(path), body))
            end

            def get(path, params = {})
                handle_response(@conn.get(fullUrl(path), params))
            end

            def handle_response(response)
                if response.success?
                response.body
                else
                raise "Operaton API Error #{response.status}: #{response.body}"
                end
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
end
