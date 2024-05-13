# frozen_string_literal: true

require "v2/bot/garbage_collector"

RSpec.describe Bot::GarbageCollector do
  before do
    connection = {
      host: "host",
      port: 5432,
      dbname: "bas",
      user: "postgres",
      password: "postgres"
    }

    config = {
      process_options: {
        connection:,
        db_table: "use_cases"
      },
      write_options: {
        connection:,
        db_table: "use_cases",
        bot_name: "GarbageCollector"
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
    let(:pg_conn) { instance_double(PG::Connection) }
    let(:pg_result) { instance_double(PG::Result) }

    before do
      @read_response = Read::Types::Response.new

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec).and_return(pg_result)
    end

    it "returns a success hash if the records were updated" do
      allow(pg_result).to receive(:res_status).and_return("PGRES_COMMAND_OK")

      processed = @bot.process(@read_response)

      expect(processed).to eq({ success: { archived: true } })
    end

    it "returns an error hash with the error message" do
      allow(pg_result).to receive(:res_status).and_return("PGRES_BAD_RESPONSE")
      allow(pg_result).to receive(:result_error_message).and_return("error_message")

      processed = @bot.process(@read_response)

      expect(processed).to eq({ error: { message: "error_message", status_code: "PGRES_BAD_RESPONSE" } })
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
      process_response = { success: { archived: true } }

      expect(@bot.write(process_response)).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      process_response = { error: { message: "error_message", status_code: "PGRES_BAD_RESPONSE" } }

      expect(@bot.write(process_response)).to_not be_nil
    end
  end
end
