# frozen_string_literal: true

require "bas/bot/format_do_bill_alert"

RSpec.describe Bot::FormatDoBillAlert do
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
        tag: "FetchBillingFromDigitalOcean"
      },
      process_options: {
        threshold: 7
      },
      write_options: {
        connection:,
        db_table: "use_cases",
        tag: "FormatDoBillAlert"
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
    let(:bill_alert_results) do
      "{\"billing\": [\
      {\"generated_at\": \"2024-07-11T06:35:00Z\", \"account_balance\": \"0\",\
      \"month_to_date_usage\": \"1\", \"month_to_date_balance\": \"1\"}]}"
    end

    let(:formatted_bill_alert) do
      { "billing" => [{ "account_balance" => "0", "generated_at" => "2024-07-11T06:35:00Z",
                        "month_to_date_balance" => "1",
                        "month_to_date_usage" => "1" }] }
    end

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[1, bill_alert_results, "date"]])
    end

    it "read the notification from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(formatted_bill_alert)
    end
  end

  describe ".process" do
    let(:bill900) do
      { "account_balance" => "0", "generated_at" => "2024-07-11T06:35:00Z",
        "month_to_date_balance" => "900",
        "month_to_date_usage" => "900" }
    end

    let(:bill800) do
      { "account_balance" => "0", "generated_at" => "2024-07-11T06:35:00Z",
        "month_to_date_balance" => "800",
        "month_to_date_usage" => "800" }
    end

    let(:bill0) do
      { "account_balance" => "0", "generated_at" => "2024-07-11T06:35:00Z",
        "month_to_date_balance" => "0",
        "month_to_date_usage" => "0" }
    end

    let(:bill_alert_exceeded) { { "billing" => bill900, "last_billing" => bill800 } }
    let(:bill_alert) { { "billing" => bill800, "last_billing" => bill800 } }
    let(:paid_bill) { { "billing" => bill0, "last_billing" => bill800 } }

    let(:formatted_alert) do
      ":warning: The **DigitalOcean** daily usage was exceeded.       Current balance: 900.0, Threshold: 7,       Current daily usage: 100.0" # rubocop:disable Layout/LineLength
    end

    it "returns an empty success hash when the billing list is empty" do
      @bot.read_response = Read::Types::Response.new(1, { "billing" => [] }, "date")

      expect(@bot.process).to eq({ success: { notification: "" } })
    end

    it "returns an empty success hash when the record was not found" do
      @bot.read_response = Read::Types::Response.new(1, nil, "date")

      expect(@bot.process).to eq({ success: { notification: "" } })
    end

    it "returns an empty success hash when the threshold was not exceeded" do
      @bot.read_response = Read::Types::Response.new(1, bill_alert, "date")
      processed = @bot.process

      expect(processed).to eq({ success: { notification: "" } })
    end

    it "returns an empty success hash when the bill was paied" do
      @bot.read_response = Read::Types::Response.new(1, paid_bill, "date")
      processed = @bot.process

      expect(processed).to eq({ success: { notification: "" } })
    end

    it "returns a success hash with the list of formatted bill alerts" do
      @bot.read_response = Read::Types::Response.new(1, bill_alert_exceeded, "date")
      processed = @bot.process

      expect(processed).to eq({ success: { notification: formatted_alert } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:formatted_alert) do
      ":warning: The **DigitalOcean** daily usage was exceeded.\n      Current balance: 800\n      Threshold: 7\n      Current daily usage: 50.0\n      " # rubocop:disable Layout/LineLength
    end

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      @bot.process_response = { success: { notification: formatted_alert } }

      expect(@bot.write).to_not be_nil
    end
  end
end
