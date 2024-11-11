# frozen_string_literal: true

require_relative "./base"

module Bot
  ##
  # The Bot::GarbageCollector class serves as a bot implementation to archive bot records from a
  # PostgresDB database table and write a response on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     process_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "use_cases"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "localhost",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "use_cases"
  #     }
  #   }
  #
  #   bot = Bot::GarbageCollector.new(options)
  #   bot.execute
  #
  class GarbageCollector < Bot::Base
    SUCCESS_STATUS = "PGRES_COMMAND_OK"

    # Process function to update records in a PostgresDB database table
    #
    def process
      response = Utils::Postgres::Request.execute(params)

      if response.res_status == SUCCESS_STATUS
        { success: { archived: true } }
      else
        { error: { message: response.result_error_message, status_code: response.res_status } }
      end
    end

    private

    def params
      {
        connection: process_options[:connection],
        query:
      }
    end

    def query
      "UPDATE #{process_options[:db_table]} SET archived=true WHERE archived=false"
    end
  end
end
