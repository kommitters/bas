# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"
require_relative "../utils/openai/run_assistant"

module Bot
  ##
  # The Bot::HumanizePto class serves as a bot implementation to read PTO's from a
  # PostgresDb table, format them using an OpenAI Assistant with the OpenAI API, and
  # write the response as a notification on a PostgresDB table.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     read_options: {
  #       connection: {
  #         host: "host",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "pto",
  #       bot_name: "FetchPtosFromNotion"
  #     },
  #     process_options: {
  #       secret: "openai secret key",
  #       assistant_id: "assistant_id",
  #       prompt: "optional additional prompt"
  #     },
  #     write_options: {
  #       connection: {
  #         host: "host",
  #         port: 5432,
  #         dbname: "bas",
  #         user: "postgres",
  #         password: "postgres"
  #       },
  #       db_table: "pto",
  #       bot_name: "HumanizePto"
  #     }
  #   }
  #
  #   bot = Bot::HumanizePto.new(options)
  #   bot.execute
  #
  class HumanizePto < Bot::Base
    DEFAULT_PROMPT = "{data}"

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options)

      reader.execute
    end

    # process function to execute the OpenaAI utility to process the PTO's
    #
    def process
      return { success: { notification: "" } } if unprocessable_response

      response = Utils::OpenAI::RunAssitant.execute(params)

      if response.code != 200 || (!response["status"].nil? && response["status"] != "completed")
        return error_response(response)
      end

      sucess_response(response)
    end

    # write function to execute the PostgresDB write component
    #
    def write
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def unprocessable_response
      read_response.data.nil? || read_response.data["ptos"] == []
    end

    def params
      {
        assistant_id: process_options[:assistant_id],
        secret: process_options[:secret],
        prompt: build_prompt
      }
    end

    def build_prompt
      prompt = process_options[:prompt] || DEFAULT_PROMPT
      ptos_list = read_response.data["ptos"]

      ptos_list_formatted_string = ptos_list.map do |pto|
        "#{pto["Name"]} is PTO from StartDateTime: #{pto["StartDateTime"]} to EndDateTime: #{pto["EndDateTime"]}"
      end.join("\n")

      prompt.gsub("{data}", ptos_list_formatted_string)
    end

    def sucess_response(response)
      { success: { notification: response.parsed_response["data"].first["content"].first["text"]["value"] } }
    end

    def error_response(response)
      { error: { message: response.parsed_response, status_code: response.code } }
    end
  end
end
