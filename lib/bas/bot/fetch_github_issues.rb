# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../utils/github/octokit_client"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::FetchGithubIssues class serves as a bot implementation to fetch GitHub issues from a
  # repository and write them on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     read_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "github_issues",
  #       tag: "FetchGithubIssues",
  #       avoid_process: true
  #     },
  #     process_options: {
  #       private_pem: "Github App private token",
  #       app_id: "Github App id",
  #       repo: "repository name",
  #       filters: "hash with filters",
  #       organization: "GitHub organization name"
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "github_issues",
  #       tag: "GithubIssueRequest"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "github_issues",
  #       tag: "FetchGithubIssues"
  #     }
  #   }
  #
  #   bot = Bot::FetchGithubIssues.new(options)
  #   bot.execute
  #
  class FetchGithubIssues < Bot::Base
    ISSUE_PARAMS = %i[id html_url title body labels state created_at updated_at].freeze
    PER_PAGE = 100

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # Process function to request GitHub issues using the octokit utility
    #
    def process
      octokit = Utils::Github::OctokitClient.new(params).execute

      if octokit[:client]
        repo_issues = octokit[:client].issues(@process_options[:repo], filters)

        normalize_response(repo_issues).each { |issue| create_request(issue) }

        { success: { created: true } }
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

    def conditions
      {
        where: "tag=$1 ORDER BY inserted_at DESC",
        params: [read_options[:tag]]
      }
    end

    def params
      {
        private_pem: process_options[:private_pem],
        app_id: process_options[:app_id],
        method: process_options[:method],
        method_params: process_options[:method_params],
        organization: process_options[:organization]
      }
    end

    def filters
      default_filter = { per_page: PER_PAGE }

      filters = @process_options[:filters]
      filters = filters.merge({ since: read_response.inserted_at }) unless read_response.nil?

      filters.is_a?(Hash) ? default_filter.merge(filters) : default_filter
    end

    def normalize_response(issues)
      issues.map do |issue|
        ISSUE_PARAMS.reduce({}) do |hash, param|
          hash.merge({ param => issue.send(param) })
              .merge({ assignees: issue.assignees.map(&:login) })
        end
      end
    end

    def create_request(issue)
      write_data = {
        success: {
          issue:,
          work_item_type: process_options[:work_item_type],
          type_id: process_options[:type_id],
          domain: process_options[:domain],
          status: process_options[:status]
        }
      }

      Write::Postgres.new(process_options, write_data).execute
    end
  end
end
