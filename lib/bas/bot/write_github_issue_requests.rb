# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::WriteGithubIssueRequests class serves as a bot implementation to write GitHub issues
  # request to be sent indiviadualy.
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
  #       tag: "FetchGithubIssues"
  #     },
  #     process_options: {
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
  #       tag: "WriteGithubIssueRequests"
  #     }
  #   }
  #
  #   bot = Bot::WriteGithubIssueRequests.new(options)
  #   bot.execute
  #
  class WriteGithubIssueRequests < Bot::Base
    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # Process function to write GitHub issues requests.
    #
    def process
      return { success: { created: nil } } if unprocessable_response

      read_response.data["issues"].each { |request| create_request(request) }

      { success: { created: true } }
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
        where: "archived=$1 AND tag=$2 AND stage=$3 ORDER BY inserted_at ASC",
        params: [false, read_options[:tag], "unprocessed"]
      }
    end

    def create_request(request)
      write_data = { success: { request: } }

      Write::Postgres.new(process_options, write_data).execute
    end
  end
end
