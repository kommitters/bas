# frozen_string_literal: true

require "httparty"

require_relative "../base"
require_relative "./types/response"
require_relative "./helper"

module Process
  module OpenAI
    ##
    # This class is an implementation of the Process::Base interface, specifically designed
    # for requesting to the OpenAI API for chat completion.
    #
    class Base < Process::Base
      OPENAI_BASE_URL = "https://api.openai.com"
      DEFAULT_N_CHOICES = 1

      # Initializes the process with essential configuration parameters.
      #
      def initialize(config = {})
        super(config)

        @n_choices = config[:n_choices] || DEFAULT_N_CHOICES
      end

      protected

      # Implements the sending process logic for the OpenAI API. It sends a
      # POST request to the OpenAI API for chat completion with the specified payload.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Formatter::Types::Response</tt> formatter response: standard formatter response
      # with the data to be send to OpenAI.
      # <br>
      # <b>raises</b> <tt>StandardError</tt> if the API returns an error response
      #
      # <br>
      # <b>returns</b> <tt>Process::Types::Response</tt>
      #
      def process(messages)
        url = "#{OPENAI_BASE_URL}/v1/chat/completions"

        httparty_response = HTTParty.post(url, { body: body(messages).to_json, headers: })

        openai_response = Process::OpenAI::Types::Response.new(httparty_response)

        response = Process::OpenAI::Helper.validate_response(openai_response)

        Process::Types::Response.new(response)
      end

      private

      def body(messages)
        {
          "model": config[:model],
          "n": @n_choices,
          "messages": messages
        }
      end

      def headers
        {
          "Authorization" => "Bearer #{config[:secret]}",
          "Content-Type" => "application/json"
        }
      end
    end
  end
end
