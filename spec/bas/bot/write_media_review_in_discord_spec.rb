# frozen_string_literal: true

require "bas/bot/write_media_review_in_discord"

RSpec.describe Bot::WriteMediaReviewInDiscord do
  before do
    connection = {
      host: "localhost",
      port: 5432,
      dbname: "bas",
      user: "postgres",
      password: "postgres"
    }

    config = {
      read_options: {
        connection:,
        db_table: "review_media",
        tag: "FormatMediaReview"
      },
      process_options: {
        secret_token: "discord_bot_token"
      },
      write_options: {
        connection:,
        db_table: "review_media",
        tag: "WriteMediaReviewInDiscord"
      }
    }

    @bot = described_class.new(config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }

    it { expect(@bot).to respond_to(:execute).with(0).arguments }
    it { expect(@bot).to respond_to(:read).with(0).arguments }
    it { expect(@bot).to respond_to(:process).with(0).arguments }
    it { expect(@bot).to respond_to(:write).with(0).arguments }

    it { expect(@bot).to respond_to(:read_options) }
    it { expect(@bot).to respond_to(:process_options) }
    it { expect(@bot).to respond_to(:write_options) }
  end

  describe ".read" do
    let(:pg_conn) { instance_double(PG::Connection) }
    let(:review_request_results) do
      "{ \"author\": \"user\", \"review\": \"simple text\", \"property\": \"images\",
        \"message_id\": \"1285685692772646922\", \"channel_id\": \"1285685692772646933\", \"media_type\": \"images\"  }"
    end

    let(:review_request) do
      { "author" => "user", "review" => "simple text", "property" => "images",
        "message_id" => "1285685692772646922", "channel_id" => "1285685692772646933", "media_type" => "images" }
    end

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[1, review_request_results, "date"]])
    end

    it "read the notification from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(review_request)
    end
  end

  describe ".process" do
    let(:review_request) do
      { "author" => "user", "review" => "simple text", "property" => "images",
        "message_id" => "1285685692772646922", "channel_id" => "1285685692772646933", "media_type" => "images" }
    end

    let(:error_response) { { "object" => "error", "message" => "Response is empty" } }

    let(:response) { double("https_response") }

    before do
      @bot.read_response = Read::Types::Response.new(1, review_request, "date")
      allow(HTTParty).to receive(:post).and_return(response)
    end

    it "returns a success hash with message_id and property to be updated" do
      allow(response).to receive(:code).and_return(200)

      processed = @bot.process

      expect(processed).to eq({ success: { message_id: review_request["message_id"],
                                           property: review_request["property"] } })
    end

    it "returns an error hash with the error message" do
      allow(Utils::Discord::Request).to receive(:split_paragraphs).and_return([])

      processed = @bot.process

      expect(processed).to eq({ error: { message: "Response is empty" } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:review_request) do
      { "created_by" => "1234567", "review" => "{\"children\": \"simple text\"}",
        "page_id" => "review_table_request", "property" => "paragraph", "media_type" => "paragraph" }
    end

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      @bot.process_response = { success: review_request }

      expect(@bot.write).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      @bot.process_response = { error: { message: error_response, status_code: 404 } }

      expect(@bot.write).to_not be_nil
    end
  end
end
