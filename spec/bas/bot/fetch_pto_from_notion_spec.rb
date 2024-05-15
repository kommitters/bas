# frozen_string_literal: true

require "bas/bot/fetch_ptos_from_notion"

RSpec.describe Bot::FetchPtosFromNotion do
  before do
    config = {
      process_options: {
        database_id: "database_id",
        secret: "secret"
      },
      write_options: {
        connection: {
          host: "host",
          port: 5432,
          dbname: "bas",
          user: "postgres",
          password: "postgres"
        },
        db_table: "pto",
        bot_name: "FetchPtosFromNotion"
      }
    }

    @bot = described_class.new(config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }

    it { expect(@bot).to respond_to(:execute).with(0).arguments }
    it { expect(@bot).to respond_to(:read).with(0).arguments }
    it { expect(@bot).to respond_to(:process).with(1).arguments }
    it { expect(@bot).to respond_to(:write).with(1).arguments }

    it { expect(@bot).to respond_to(:read_options) }
    it { expect(@bot).to respond_to(:process_options) }
    it { expect(@bot).to respond_to(:write_options) }
  end

  describe ".read" do
    it { expect(@bot.read).to be_a Read::Types::Response }
  end

  describe ".process" do
    let(:pto) do
      {
        "properties" => {
          "Description" => { "title" => [{ "plain_text" => "John Doe" }] },
          "StartDateTime" => { "date" => { "start" => "2024-05-01", "end" => "" } },
          "EndDateTime" => { "date" => { "start" => "2024-05-02", "end" => "" } }
        }
      }
    end

    let(:formatted_pto) do
      {
        "Name" => "John Doe",
        "StartDateTime" => { from: "2024-05-01", to: "" },
        "EndDateTime" => { from: "2024-05-02", to: "" }
      }
    end

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    let(:response) { double("http_response") }

    before do
      @read_response = Read::Types::Response.new

      allow(HTTParty).to receive(:send).and_return(response)
    end

    it "returns a success hash with the list of formatted ptos" do
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:parsed_response).and_return({ "results" => [pto] })

      processed = @bot.process(@read_response)

      expect(processed).to eq({ success: { ptos: [formatted_pto] } })
    end

    it "returns an error hash with the error message" do
      allow(response).to receive(:code).and_return(404)
      allow(response).to receive(:parsed_response).and_return(error_response)

      processed = @bot.process(@read_response)

      expect(processed).to eq({ error: { message: error_response, status_code: 404 } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:formatted_pto) do
      {
        "Name" => "John Doe",
        "StartDateTime" => { from: "2024-05-01", to: "" },
        "EndDateTime" => { from: "2024-05-02", to: "" }
      }
    end

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      process_response = { success: { ptos: [formatted_pto] } }

      expect(@bot.write(process_response)).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      process_response = { error: { message: error_response, status_code: 404 } }

      expect(@bot.write(process_response)).to_not be_nil
    end
  end
end
