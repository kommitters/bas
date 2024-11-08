# frozen_string_literal: true

require_relative "./base"
require_relative "../utils/openai/run_assistant"

module Bot
  ##
  # The Bot::ReviewMedia class serves as a bot implementation to read from a postgres
  # shared storage a images hash with a specific format and create single request
  # on the shared storage to be processed one by one.
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
  #       tag: "ReviewMediaRequest"
  #     },
  #     process_options: {
  #       secret: "openai_secret",
  #       assistant_id: "openai_assistant_id",
  #       media_type: "images"
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
  #       tag: "ReviewText"
  #     }
  #   }
  #
  #   bot = Bot::ReviewMedia.new(options)
  #   bot.execute
  #
  class ReviewMedia < Bot::Base
    DETAIL = "low"

    # process function to execute the OpenaAI utility to process the media reviews
    #
    def process
      return { success: { review: nil } } if unprocessable_response

      response = Utils::OpenAI::RunAssitant.execute(params)

      if response.code != 200 || (!response["status"].nil? && response["status"] != "completed")
        return error_response(response)
      end

      success_response(response)
    end

    private

    def params
      {
        assistant_id: process_options[:assistant_id],
        secret: process_options[:secret],
        prompt: build_prompt
      }
    end

    def build_prompt
      case process_options[:media_type]
      when "images" then images_media
      when "paragraph" then text_media
      end
    end

    def images_media
      read_response.data["media"].map { |url| { type: "image_url", image_url: { url:, detail: DETAIL } } }
    end

    def text_media
      read_response.data["media"]
    end

    def success_response(response)
      review = get_review(response)
      { success: media_hash.merge({ review: }) }
    end

    def get_review(response)
      response.parsed_response["data"].first["content"].first["text"]["value"]
    end

    def media_hash
      {
        message_id: read_response.data["message_id"],
        channel_id: read_response.data["channel_id"],
        property: read_response.data["property"],
        author: read_response.data["author"],
        media_type: process_options[:media_type]
      }
    end

    def error_response(response)
      { error: { message: response.parsed_response, status_code: response.code } }
    end
  end
end
