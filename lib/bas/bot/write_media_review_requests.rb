# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::WriteMediaReviewRequests class serves as a bot implementation to read from a postgres
  # shared storage a set of review media requests and create single request on the shared storage to
  # be processed one by one.
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
  #       db_table: "review_media",
  #       tag: "FetchMediaFromNotion"
  #     },
  #     process_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "review_media",
  #       tag: "ReviewMediaRequest"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "review_media",
  #       tag: "WriteMediaReviewRequests"
  #     }
  #   }
  #
  #   bot = Bot::WriteMediaReviewRequests.new(options)
  #   bot.execute
  #
  class WriteMediaReviewRequests < Bot::Base
    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # Process function to execute the Notion utility create single review requests
    #
    def process
      return { success: { created: nil } } if unprocessable_response

      read_response.data["results"].each { |request| create_request(request) }

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
      write_data = write_request(request)

      Write::Postgres.new(process_options, write_data).execute
    end

    def write_request(request)
      return { error: request } if request["media"].empty? || !request["error"].nil?

      { success: request }
    end
  end
end
