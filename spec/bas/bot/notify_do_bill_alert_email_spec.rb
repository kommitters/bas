# frozen_string_literal: true

require "bas/bot/notify_do_bill_alert_email"

RSpec.describe Bot::NotifyDoBillAlertEmail do
  before do
    config = {
      read_options: {
        connection: {
          host: "localhost",
          port: 5432,
          dbname: "bas",
          user: "postgres",
          password: "postgres"
        },
        db_table: "do_billing",
        tag: "FormatDoBillAlert"
      },
      process_options: {
        refresh_token: "refresh_token",
        client_id: "client_id",
        client_secret: "client_secret",
        user_email: "example@gmail.com",
        recipient_email: ["recipient1@mail.co", "recipient2@mail.co"]
      },
      write_options: {
        connection: {
          host: "localhost",
          port: 5432,
          dbname: "bas",
          user: "postgres",
          password: "postgres"
        },
        db_table: "do_billing",
        tag: "NotifyDoBillAlertEmail"
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
      allow(@pg_result).to receive(:values).and_return([[1, "{\"notification\": \"Bill exceeded\"}", "date"]])
    end

    it "read the notification from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
    end
  end

  describe ".process" do
    let(:error) { double("error", execute: { error: "there was an error" }) }
    let(:email_success) { double("result", execute: {}) }

    before do
      @bot.read_response = Read::Types::Response.new(1, { "notification" => "Alert was found" }, "date")
    end

    it "returns a success hash with list of emails" do
      allow(Utils::GoogleService::SendEmail).to receive(:new).and_return(email_success)

      processed = @bot.process

      expect(processed[:success]).to eq({})
    end

    it "returns an error hash when the utility faile" do
      allow(Utils::GoogleService::SendEmail).to receive(:new).and_return(error)

      processed = @bot.process

      expect(processed).to eq({ error: { error: "there was an error" } })
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
      @bot.process_response = { success: {} }

      expect(@bot.write).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      @bot.process_response = { error: { message: error_response, status_code: 404 } }

      expect(@bot.write).to_not be_nil
    end
  end
end
