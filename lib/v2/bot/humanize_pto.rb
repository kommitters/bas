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
      # TODO: Check when the read_response is nil so that we don't have to humanize any PTO
      params = {
        secret: process_options[:secret],
        model: process_options[:model],
        messages: messages(read_response)
      }

      openai_response = Utils::OpenAI::ChatCompletion.execute(params)

      manage_response(openai_response)
    end

    def manage_response(openai_response)
      return success_response(openai_response) if openai_response.code == 200

      error_response(openai_response)
    end

    def write(process_response)
      write = Write::Postgres.new(write_options, process_response)

      write.execute
    end

    private

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

    def success_response(openai_response)
      { success: {
        notification: openai_response.parsed_response["choices"].first["message"]["content"]
      } }
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
