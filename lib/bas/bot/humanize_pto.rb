# frozen_string_literal: true

require_relative "./base"
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
  #       tag: "FetchPtosFromNotion"
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
  #       tag: "HumanizePto"
  #     }
  #   }
  #
  #   bot = Bot::HumanizePto.new(options)
  #   bot.execute
  #
  class HumanizePto < Bot::Base
    DEFAULT_PROMPT = "{data}"

    # process function to execute the OpenaAI utility to process the PTO's
    #
    def process
      return { success: { notification: "" } } if unprocessable_response

      response = Utils::OpenAI::RunAssitant.execute(params)

      if response.code != 200 || (!response["status"].nil? && response["status"] != "completed")
        return error_response(response)
      end

      success_response(response)
    end

    private

    def conditions
      {
        where: "archived=$1 AND tag=$2 AND stage=$3 ORDER BY inserted_at ASC",
        params: [false, read_options[:tag], "unprocessed"]
      }
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

      ptos_list_formatted_string = ptos_list.join("\n")

      prompt.gsub("{data}", ptos_list_formatted_string)
    end

    def success_response(response)
      { success: { notification: response.parsed_response["data"].first["content"].first["text"]["value"] } }
    end

    def error_response(response)
      { error: { message: response.parsed_response, status_code: response.code } }
    end
  end
end
