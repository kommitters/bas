# frozen_string_literal: true

require "bas/bot/format_emails"

RSpec.describe Bot::FormatEmails do
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
        tag: "FetchEmailsFromImap"
      },
      process_options: {
        template: "The <sender> has requested support the <date>"
      },
      write_options: {
        connection:,
        db_table: "use_cases",
        tag: "FormatEmails"
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
    let(:emails_results) do
      "{\"emails\": [{\"date\": \"Thu, 09 May\", \"sender\": \"user@mail.com\"}]}"
    end

    let(:formatted_emails) do
      { "emails" => [{ "date" => "Thu, 09 May", "sender" => "user@mail.com" }] }
    end

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[emails_results]])
    end

    it "read the notification from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(formatted_emails)
    end
  end

  describe ".process" do
    let(:emails) { [{ "date" => "Thu, 09 May", "sender" => "user@mail.com" }] }

    let(:formatted_emails) do
      " The user@mail.com has requested support the 2024-05-09 12:00:00 AM \n"
    end

    it "returns an empty success hash when the birthdays list is empty" do
      @bot.read_response = Read::Types::Response.new({ "emails" => [] })

      expect(@bot.process).to eq({ success: { notification: "" } })
    end

    it "returns an empty success hash when the record was not found" do
      @bot.read_response = Read::Types::Response.new(nil)

      expect(@bot.process).to eq({ success: { notification: "" } })
    end

    it "returns a success hash with the list of formatted birthdays" do
      @bot.read_response = Read::Types::Response.new({ "emails" => emails })
      processed = @bot.process

      expect(processed).to eq({ success: { notification: formatted_emails } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:formatted_emails) do
      " The user@mail.com has requested support the Thu, 09 May \n"
    end

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      @bot.process_response = { success: { notification: formatted_emails } }

      expect(@bot.write).to_not be_nil
    end
  end
end
