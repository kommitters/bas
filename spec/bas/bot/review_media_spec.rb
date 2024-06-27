# frozen_string_literal: true

require "bas/bot/review_media"

RSpec.describe Bot::ReviewMedia do
  before do
    connection = {
      host: "host",
      port: 5432,
      dbname: "bas",
      user: "postgres",
      password: "postgres"
    }

    config = {
      read_options: {
        connection:,
        db_table: "review_media",
        tag: "ReviewMediaRequest"
      },
      process_options: {
        assistant_id: "assistant_id",
        secret: "secret",
        media_type: "paragraph"
      },
      write_options: {
        connection:,
        db_table: "review_media",
        tag: "ReviewText"
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
      "{ \"created_by\": \"1234567\", \"media\": \"simple text\",
      \"page_id\": \"review_table_request\", \"property\": \"paragraph\" }"
    end

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[1, review_request_results, "date"]])
    end

    it "read the review request from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
    end
  end

  describe ".process" do
    let(:review_request) do
      { "created_by" => "1234567", "media" => "simple text",
        "page_id" => "review_table_request", "property" => "paragraph" }
    end

    let(:run) { double("run", parsed_response: { "id" => "run_id", "thread_id" => "thread_id" }) }
    let(:pol) { double("pol", parsed_response: { error: { message: "pol run fail" } }) }
    let(:list) { double("list", parsed_response: { error: { message: "list message fail" } }) }
    let(:success) { { "data" => [{ "content" => [{ "text" => { "value" => "notification" } }] }] } }

    let(:error_response) { { "code": 50_027, "message": "Invalid Webhook Token" } }

    before do
      @bot.read_response = Read::Types::Response.new(1, review_request, "date")

      allow(HTTParty).to receive(:post).and_return(run)
      allow(HTTParty).to receive(:get).and_return(pol, list)
    end

    it "returns an empty success hash when the media is empty" do
      @bot.read_response = Read::Types::Response.new(1, {}, "date")

      expect(@bot.process).to eq({ success: { review: nil } })
    end

    it "returns an empty success hash when the record was not found" do
      @bot.read_response = Read::Types::Response.new(1, nil, "date")

      expect(@bot.process).to eq({ success: { review: nil } })
    end

    it "returns an error when the thread and run build fail" do
      allow(run).to receive(:code).and_return(404)
      allow(run).to receive(:[]).and_return("completed")

      response = @bot.process

      expect(response).to eq({ error: { message: { "id" => "run_id", "thread_id" => "thread_id" },
                                        status_code: 404 } })
    end

    it "returns an error when the pol run fail" do
      allow(run).to receive(:code).and_return(200)
      allow(pol).to receive(:[]).and_return("failed")
      allow(pol).to receive(:code).and_return(401)

      response = @bot.process

      expect(response).to eq({ error: { message: { error: { message: "pol run fail" } },
                                        status_code: 401 } })
    end

    it "returns an error when the list messages endpoint fail" do
      allow(run).to receive(:code).and_return(200)
      allow(pol).to receive(:[]).and_return("completed")
      allow(pol).to receive(:code).and_return(200)
      allow(list).to receive(:code).and_return(500)

      response = @bot.process

      expect(response).to eq({ error: { message: { error: { message: "list message fail" } },
                                        status_code: 500 } })
    end

    it "returns a success when the openai assistant returns response" do
      allow(run).to receive(:code).and_return(200)
      allow(pol).to receive(:[]).and_return("completed")
      allow(pol).to receive(:code).and_return(200)
      allow(list).to receive(:code).and_return(200)
      allow(list).to receive(:[]).and_return("completed")
      allow(list).to receive(:parsed_response).and_return(success)

      @bot.process
    end
  end

  describe ".write" do
    let(:error_response) { { "code": 50_027, "message": "Invalid Webhook Token" } }

    before do
      pg_conn = instance_double(PG::Connection)
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      @bot.process_response = { success: {} }

      expect(@bot.write).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      @bot.process_response = { error: { message: error_response, status_code: 401 } }

      expect(@bot.write).to_not be_nil
    end
  end
end
