# frozen_string_literal: true

require_relative "./base"
require_relative "../read/default"
require_relative "../utils/github/octokit_client"
require_relative "../write/postgres"

module Bot
  class FetchGithubIssues < Bot::Base
    ISSUE_PARAMS = %i[id url title body labels state created_at updated_at].freeze
    PER_PAGE = 100

    # Read function to execute the default Read component
    #
    def read
      reader = Read::Default.new

      reader.execute
    end

    # Process function to request email from an imap server using the imap utility
    #
    def process
      octokit = Utils::Github::OctokitClient.new(params).execute

      if octokit[:client]
        repo_issues = octokit[:client].issues(@process_options[:repo], filters)
        issues = normalize_response(repo_issues)

        { success: { issues: } }
      else
        { error: octokit[:error] }
      end
    end

    # Write function to execute the PostgresDB write component
    #
    def write
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def params
      {
        private_pem: process_options[:private_pem],
        app_id: process_options[:app_id],
        method: process_options[:method],
        method_params: process_options[:method_params]
      }
    end

    def filters
      default_filter = { per_page: PER_PAGE }
      filters = @process_options[:filters]

      filters.is_a?(Hash) ? default_filter.merge(filters) : default_filter
    end

    def normalize_response(issues)
      issues.map do |issue|
        ISSUE_PARAMS.reduce({}) { |hash, param| hash.merge({ param => issue.send(param) }) }
      end
    end
  end
end
