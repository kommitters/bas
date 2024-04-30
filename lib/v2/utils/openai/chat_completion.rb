# frozen_string_literal: true

require "pg"

module Utils
  module OpenAI
    module ChatCompletion
      OPENAI_BASE_URL = "https://api.openai.com"
      DEFAULT_N_CHOICES = 1

      def self.execute(params)
        url = "#{OPENAI_BASE_URL}/v1/chat/completions"

        HTTParty.post(url, { body: body(params).to_json, headers: headers(params) })
      end

      def self.body(params)
        {
          "model": params[:model],
          "n": params[:n_choices] || DEFAULT_N_CHOICES,
          "messages": params[:messages]
        }
      end

      def self.headers(params)
        {
          "Authorization" => "Bearer #{params[:secret]}",
          "Content-Type" => "application/json"
        }
      end
    end
  end
end
