# frozen_string_literal: true

require "bas/bot/fetch_billing_from_digital_ocean"

RSpec.describe Bot::FetchBillingFromDigitalOcean do
  before do
    connection = {
      host: "localhost",
      port: 5432,
      dbname: "bas",
      user: "postgres",
      password: "postgres"
    }

    config = {
      process_options: {
        database_id: "database_id",
        secret: "secret"
      },
      write_options: {
        connection:,
        db_table: "use_cases",
        tag: "FetchBillingFromDigitalOcean"
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
    let(:billing_results) do
      "{\"billing\": {\"generated_at\": \"2024-08-27T05:09:37Z\",
        \"account_balance\": \"0.00\",
        \"month_to_date_usage\": \"0\",
        \"month_to_date_balance\": \"0\"}
      }"
    end

    let(:formatted_billing) do
      { "billing" => {
        "generated_at" => "2024-08-27T05:09:37Z", "account_balance" => "0.00",
        "month_to_date_usage" => "0", "month_to_date_balance" => "0"
      } }
    end

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[1, billing_results, "date"]])
    end

    it "read the notification from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(formatted_billing)
    end
  end

  describe ".process" do
    let(:do_bill) do
      {
        "generated_at": "2024-07-11T06:35:00Z",
        "account_balance": "0.00",
        "month_to_date_usage": "1",
        "month_to_date_balance": "1"
      }
    end

    let(:last_billing) do
      {
        "generated_at" => "2024-08-27T05:09:37Z", "account_balance" => "0.00",
        "month_to_date_usage" => "1", "month_to_date_balance" => "1"
      }
    end

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    let(:response) { double("http_response") }

    before do
      @bot.read_response = Read::Types::Response.new

      allow(HTTParty).to receive(:send).and_return(response)
    end

    it "returns a success hash with the digital ocean bill when a last billing was found" do
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:parsed_response).and_return(do_bill)

      @bot.read_response = Read::Types::Response.new(1, nil, "date")

      processed = @bot.process

      expect(processed).to eq({ success: { billing: do_bill, last_billing: nil } })
    end

    it "returns a success hash with the digital ocean bill when a last billing was not found" do
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:parsed_response).and_return(do_bill)

      @bot.read_response = Read::Types::Response.new(1, { "billing" => last_billing }, "date")

      processed = @bot.process

      expect(processed).to eq({ success: { billing: do_bill, last_billing: } })
    end

    it "returns an error hash with the error message" do
      allow(response).to receive(:code).and_return(404)
      allow(response).to receive(:parsed_response).and_return(error_response)

      processed = @bot.process

      expect(processed).to eq({ error: { message: error_response, status_code: 404 } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:formatted_do_bill) do
      {
        "generated_at": "2024-07-11T06:35:00Z",
        "account_balance": "0.00",
        "month_to_date_usage": "1",
        "month_to_date_balance": "1"
      }
    end

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      @bot.process_response = { success: { billing: formatted_do_bill } }

      expect(@bot.write).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      @bot.process_response = { error: { message: error_response, status_code: 404 } }

      expect(@bot.write).to_not be_nil
    end
  end
end
