# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../write/postgres"
require_relative "../utils/openai/chat_completion"

module Bot
  class HumanizePto < Bot::Base
    def read
      reader = Read::Postgres.new(read_options)

      reader.execute
    end

    def process(read_response)
      return { success: { notification: "" } } if read_response.data.nil? || read_response.data["ptos"] == []

      params = build_params(read_response)
      response = Utils::OpenAI::ChatCompletion.execute(params)

      if response.code == 200
        { success: { notification: response.parsed_response["choices"].first["message"]["content"] } }
      else
        { error: { message: response.parsed_response, status_code: response.code } }
      end
    end

    def write(process_response)
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

    def build_params(read_response)
      {
        secret: process_options[:secret],
        model: process_options[:model],
        messages: messages(read_response)
      }
    end

    def messages(read_response)
      [
        {
          "role": "user",
          "content": content(read_response)
        }
      ]
    end

    def content(read_response)
      ptos_list = read_response.data["ptos"]

      ptos_list_formatted_string = ptos_list.map do |pto|
        "#{pto["Name"]} is PTO from StartDateTime: #{pto["StartDateTime"]} to EndDateTime: #{pto["EndDateTime"]}"
      end.join("\n")

      process_options[:prompt].gsub("{data}", ptos_list_formatted_string)
    end

    def error_response(openai_response)
      {
        error: {
          message: openai_response.parsed_response,
          status_code: openai_response.code
        }
      }
    end
  end
end
