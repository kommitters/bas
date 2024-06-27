# frozen_string_literal: true

require "bas/bot/write_media_review_requests"

RSpec.describe Bot::WriteMediaReviewRequests do
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
        db_table: "use_cases",
        tag: "FetchMediaFromNotion"
      },
      process_options: {
        connection:,
        db_table: "use_cases",
        tag: "ReviewMediaRequest"
      },
      write_options: {
        connection:,
        db_table: "use_cases",
        tag: "WriteMediaReviewRequests"
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
      "[{ \"created_by\": \"1234567\", \"media\": \"simple text\",
      \"page_id\": \"review_table_request\", \"property\": \"paragraph\" }]"
    end

    let(:formatted_review_request) do
      [{ "created_by" => "1234567", "media" => "simple text",
         "page_id" => "review_table_request", "property" => "paragraph" }]
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
      expect(read.data).to be_a Array
      expect(read.data.first).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(formatted_review_request)
    end
  end

  describe ".process" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:review_request) do
      [{ "created_by" => "1234567", "media" => "simple text",
         "page_id" => "review_table_request", "property" => "paragraph" }]
    end

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "returns an empty success hash when the media list is empty" do
      @bot.read_response = Read::Types::Response.new(1, { "media" => [] }, "date")

      expect(@bot.process).to eq({ success: { created: nil } })
    end

    it "returns an empty success hash when the record was not found" do
      @bot.read_response = Read::Types::Response.new(1, nil, "date")

      expect(@bot.process).to eq({ success: { created: nil } })
    end

    it "returns a success hash after writting the requests in the shared storage" do
      @bot.read_response = Read::Types::Response.new(1, review_request, "date")

      processed = @bot.process

      expect(processed).to eq({ success: { created: true } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      @bot.process_response = { success: { created: true } }

      expect(@bot.write).to_not be_nil
    end
  end
end
