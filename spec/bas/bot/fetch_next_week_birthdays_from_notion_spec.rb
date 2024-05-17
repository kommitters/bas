# frozen_string_literal: true

require "bas/bot/fetch_next_week_birthdays_from_notion"

RSpec.describe Bot::FetchNextWeekBirthdaysFromNotion do
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
        tag: "FetchBirthdaysFromNotion"
      },
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
        db_table: "use_cases",
        tag: "FetchNextWeekBirthdaysFromNotion"
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
    let(:birthdays_results) do
      "{\"birthdays\": [\
      {\"name\": \"John Doe\", \"birthday_date\": \"2024-05-03\"},\
      {\"name\": \"Jane Doe\", \"birthday_date\": \"2024-05-03\"}\
      ]}"
    end

    let(:formatted_birthdays) do
      { "birthdays" => [{ "name" => "John Doe", "birthday_date" => "2024-05-03" },
                        { "name" => "Jane Doe", "birthday_date" => "2024-05-03" }] }
    end

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[1, birthdays_results, "date"]])
    end

    it "read the notification from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(formatted_birthdays)
    end
  end

  describe ".process" do
    let(:birthday) do
      {
        "properties" => {
          "Complete Name" => { "rich_text" => [{ "plain_text" => "John Doe" }] },
          "BD_this_year" => { "formula" => { "date" => { "start" => "2024-05-01" } } }
        }
      }
    end

    let(:formatted_birthday) do
      {
        "name" => "John Doe",
        "birthday_date" => "2024-05-01"
      }
    end

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    let(:response) { double("http_response") }

    before do
      @bot.read_response = Read::Types::Response.new

      allow(HTTParty).to receive(:send).and_return(response)
    end

    it "returns a success hash with the list of formatted birthdays" do
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:parsed_response).and_return({ "results" => [birthday] })

      processed = @bot.process

      expect(processed).to eq({ success: { birthdays: [formatted_birthday] } })
    end

    it "returns a success hash with the list of formatted new birthdays" do
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:parsed_response).and_return({ "results" => [birthday] })

      @bot.read_response = Read::Types::Response.new(1, birthday, "date")

      processed = @bot.process

      expect(processed).to eq({ success: { birthdays: [formatted_birthday] } })
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

    let(:formatted_birthday) do
      {
        "name" => "John Doe",
        "birthday_date" => "2024-05-01"
      }
    end

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      @bot.process_response = { success: { birthdays: [formatted_birthday] } }

      expect(@bot.write).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      @bot.process_response = { error: { message: error_response, status_code: 404 } }

      expect(@bot.write).to_not be_nil
    end
  end
end
