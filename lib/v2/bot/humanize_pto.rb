# frozen_string_literal: true

require "httparty"

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"
require_relative "../utils/openai/run_assistant"

module Bot
  class HumanizePto < Bot::Base
    DEFAULT_PROMPT = "{data}"

    def read
      reader = Read::Postgres.new(read_options)

      reader.execute
    end

    def process(read_response)
      # Handle when no PTO records are available, or when no data is available due to errors in the previous bot process
      return { success: { notification: "" } } if read_response.data.nil? || read_response.data["ptos"] == []

      params = build_params(read_response)
      response = Utils::OpenAI::RunAssitant.execute(params)

      return error_response(response) if response["status"] == "completed" || response.code != 200

      sucess_response(response)
    end

    def write(process_response)
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def build_params(read_response)
      {
        assistant_id: process_options[:assistant_id],
        secret: process_options[:secret],
        prompt: build_prompt(read_response)
      }
    end

    def build_prompt(read_response)
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
