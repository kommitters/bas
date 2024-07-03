# frozen_string_literal: true

require_relative "./base"
require_relative "../read/postgres"
require_relative "../utils/notion/request"
require_relative "../write/postgres"

module Bot
  ##
  # The Bot::FetchMediaFromNotion class serves as a bot implementation to read media (text or images)
  # from a notion database and write them on a PostgresDB table with a specific format.
  #
  # <br>
  # <b>Example</b>
  #
  #   options = {
  #     process_options: {
  #       database_id: "notion_database_id",
  #       secret: "notion_secret",
  #       property: "paragraph"
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
  #       tag: "FetchMediaFromNotion"
  #     }
  #   }
  #
  #   bot = Bot::FetchMediaFromNotion.new(options)
  #   bot.execute
  #
  class FetchMediaFromNotion < Bot::Base # rubocop:disable Metrics/ClassLength
    CONTENT_STATUS = "review"

    # read function to execute the PostgresDB Read component
    #
    def read
      reader = Read::Postgres.new(read_options.merge(conditions))

      reader.execute
    end

    # Process function to execute the Notion utility to fetch media from a notion database
    #
    def process
      media_response = fetch_media

      return media_response unless media_response[:error].nil?

      { success: media_response }
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
        where: "archived=$1 AND tag=$2 ORDER BY inserted_at DESC",
        params: [false, read_options[:tag]]
      }
    end

    def fetch_media
      request_ids_response = fetch_requests_ids

      return request_ids_response unless request_ids_response[:error].nil?

      { results: fetch_pages(request_ids_response[:ids]) }
    end

    def fetch_requests_ids
      response = Utils::Notion::Request.execute(params_database)

      return error(response) unless response.code == 200

      { ids: response["results"]&.map { |result| result["id"] } }
    end

    def fetch_pages(pages_ids)
      pages_ids.map do |page_id|
        content_response = fetch_content(page_id)

        process_content(page_id, content_response)
      end
    end

    def process_content(page_id, content)
      return content unless content[:error].nil?

      filter_media(page_id, content[:results])
    end

    def filter_media(page_id, page_content)
      medias = page_content.select { |content| content["type"] == process_options[:property] }

      media = extract_content(medias)
      created_by = medias.first["created_by"]["id"] unless medias.first.nil?

      { media:, page_id:, created_by:, property: process_options[:property] }
    end

    def extract_content(content)
      case process_options[:property]
      when "image" then process_images(content)
      when "paragraph" then process_text(content)
      end
    end

    def process_images(images)
      images.map { |image| image["image"]["file"]["url"] }
    end

    def process_text(texts)
      texts.reduce("") do |paragraph, text|
        rich_text = text["paragraph"]["rich_text"].map { |plain_text| plain_text["plain_text"] }

        content = rich_text.empty? ? "" : rich_text.join(" ")

        "#{paragraph}\n#{content}"
      end
    end

    def fetch_content(block_id)
      response = fetch_block(block_id)

      return error(response) unless response.code == 200

      { results: response["results"] }
    end

    def error(response)
      { error: { message: response.parsed_response, status_code: response.code } }
    end

    def params_database
      {
        endpoint: "databases/#{process_options[:database_id]}/query",
        secret: process_options[:secret],
        method: "post",
        body: body_database
      }
    end

    def body_database
      { filter: { and: [] + property_condition + time_condition } }
    end

    def property_condition
      [{ property: process_options[:property], select: { equals: CONTENT_STATUS } }]
    end

    def time_condition
      return [] if read_response.inserted_at.nil?

      [{ property: "Last edited time", last_edited_time: { on_or_after: read_response.inserted_at } }]
    end

    def fetch_block(block_id)
      params = block_params(block_id)

      Utils::Notion::Request.execute(params)
    end

    def block_params(block_id)
      {
        endpoint: "blocks/#{block_id}/children",
        secret: process_options[:secret],
        method: "get",
        body: {}
      }
    end
  end
end
