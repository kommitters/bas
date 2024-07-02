# frozen_string_literal: true

require "bas/bot/fetch_media_from_notion"

RSpec.describe Bot::FetchMediaFromNotion do
  before do
    config = {
      process_options: {
        database_id: "database_id",
        secret: "secret",
        property: "paragraph"
      },
      write_options: {
        connection: {
          host: "host",
          port: 5432,
          dbname: "bas",
          user: "postgres",
          password: "postgres"
        },
        db_table: "use_cases",
        tag: "FetchMediaFromNotion"
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

    it "read the review requests from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Array
      expect(read.data.first).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(formatted_review_request)
    end
  end

  describe ".process paragraph" do
    let(:request_page_ids) { [{ "id" => "review_table_request" }] }
    let(:content_page) do
      [{ "created_by" => { "id" => "1234567" }, "type" => "paragraph",
         "paragraph" => { "rich_text" => [{ "plain_text" => "simple text" }] } }]
    end

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }
    let(:response) { double("http_response") }

    before do
      @bot.read_response = Read::Types::Response.new

      allow(HTTParty).to receive(:send).and_return(response)
    end

    it "returns a success hash with the media review requests" do
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:[]).and_return(request_page_ids, content_page)

      processed = @bot.process

      expect(processed).to eq({ success: { results: [{ created_by: "1234567", media: "\nsimple text",
                                                       page_id: "review_table_request", property: "paragraph" }] } })
    end

    it "returns an error hash with the error message when request id failed" do
      allow(response).to receive(:code).and_return(404)
      allow(response).to receive(:parsed_response).and_return(error_response)

      processed = @bot.process

      expect(processed).to eq({ error: { message: error_response, status_code: 404 } })
    end

    it "returns an error hash with the error message when request page id failed" do
      allow(response).to receive(:code).and_return(200, 404)
      allow(response).to receive(:[]).and_return(request_page_ids)
      allow(response).to receive(:parsed_response).and_return(error_response)

      processed = @bot.process

      expect(processed).to eq({ success: { results: [{ error: {
                                message: { "message" => "not found", "object" => "error",
                                           "status" => 404 }, status_code: 404
                              } }] } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      @bot.process_response = { success: [{ "created_by" => "1234567", "media" => "simple text",
                                            "page_id" => "review_table_request", "property" => "paragraph" }] }

      expect(@bot.write).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      @bot.process_response = { error: { message: error_response, status_code: 404 } }

      expect(@bot.write).to_not be_nil
    end
  end
end
