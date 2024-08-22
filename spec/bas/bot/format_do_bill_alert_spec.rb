# frozen_string_literal: true

require "bas/bot/format_do_bill_alert"
require "active_support/core_ext/string"

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
    let(:bill_alert) do
      { "billing" => { "account_balance" => "0", "generated_at" => "2024-07-11T06:35:00Z",
                       "month_to_date_balance" => "800",
                       "month_to_date_usage" => "800" } }
    end

    let(:formatted_alert) do
      daily_usage = 800.0 / Time.now.utc.mday

      ":warning: The **DigitalOcean** daily usage was exceeded. Current balance: 800.0, Threshold: 7, Current daily usage: #{daily_usage.round(3)}"
    end

    let(:previous_bill_alert) do
      { "billing" => { "account_balance" => "0", "generated_at" => "2024-07-10T06:35:00Z",
                       "month_to_date_balance" => "750",
                       "month_to_date_usage" => "750" } }
    end

    before do
      pg_result = double("PG::Result")
      allow(pg_result).to receive(:values).and_return([[1, previous_bill_alert.to_json, "date"]])

      pg_conn = instance_double(PG::Connection)
      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)

      mock_data = { "billing" => { "account_balance" => "0", "generated_at" => "2024-07-11T06:35:00Z",
                                   "month_to_date_balance" => "800",
                                   "month_to_date_usage" => "800" } }

      @mock_read_response = instance_double("Read::Types::Response", data: mock_data)

      @bot.instance_variable_set(:@read_response, @mock_read_response)
      @bot.instance_variable_set(:@previous_billing_data, previous_bill_alert)
      @bot.instance_variable_set(:@current_billing_data, bill_alert)
    end

    it "returns a success hash with the list of formatted bill alerts" do
      allow(@bot).to receive(:read_response).and_return(@mock_read_response)

      processed = @bot.process

      expect(processed[:success][:notification].squish).to eq(formatted_alert.squish)
    end

    it "skips processing when unprocessable_response is true" do
      allow(@bot).to receive(:unprocessable_response).and_return(true)

      expect(@bot.send(:skip_processing?)).to be true
    end

    it "skips processing when conditions are not met" do
      allow(@bot).to receive(:significant_change?).and_return(true)
      allow(@bot).to receive(:threshold_exceeded).and_return(false)

      expect(@bot.send(:skip_processing?)).to be true
    end

    it "does not skip processing when conditions are met" do
      allow(@bot).to receive(:significant_change?).and_return(false)
      allow(@bot).to receive(:threshold_exceeded).and_return(false)

      expect(@bot.send(:skip_processing?)).to be false
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:formatted_alert) do
      ":warning: The **DigitalOcean** daily usage was exceeded.\n Current balance: 800.0\n Threshold: 7\n Current daily usage: 50.0\n"
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
