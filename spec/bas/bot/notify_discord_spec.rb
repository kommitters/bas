# frozen_string_literal: true

require "bas/bot/notify_discord"

RSpec.describe Bot::NotifyDiscord do
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
        db_table: "pto",
        tag: "HumanizePto"
      },
      process_options: {
        name: "discordBotName",
        webhook: "webhook"
      },
      write_options: {
        connection:,
        db_table: "pto",
        tag: "NotifyDiscord"
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

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[1, "{\"notification\": \"John Doe is on PTO\"}", "date"]])
    end

    it "read the notification from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
    end
  end

  describe ".process" do
    let(:response) { double("http_response") }
    let(:error_response) { { "code": 50_027, "message": "Invalid Webhook Token" } }

    before do
      @bot.read_response = Read::Types::Response.new(1, { notification: "John Doe is on PTO" }, "date")

      allow(HTTParty).to receive(:post).and_return(response)
    end

    it "returns an empty success hash when the notification is empty" do
      @bot.read_response = Read::Types::Response.new(1, { "notification" => "" }, "date")

      expect(@bot.process).to eq({ success: {} })
    end

    it "returns an empty success hash when the record was not found" do
      @bot.read_response = Read::Types::Response.new(1, nil, "date")

      expect(@bot.process).to eq({ success: {} })
    end

    it "returns a success hash with the notified message" do
      allow(response).to receive(:code).and_return(204)

      process = @bot.process

      expect(process).to eq({ success: {} })
    end

    it "returns an error hash with the error message" do
      allow(response).to receive(:code).and_return(401)
      allow(response).to receive(:parsed_response).and_return(error_response)

      process = @bot.process

      expect(process).to eq({ error: { message: error_response, status_code: 401 } })
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
