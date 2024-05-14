# frozen_string_literal: true

require "bas/bot/format_birthdays"

RSpec.describe Bot::FormatBirthdays do
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
        bot_name: "FetchBirthdaysFromNotion"
      },
      process_options: {
        template: "<name>, Wishing you a very happy birthday!"
      },
      write_options: {
        connection:,
        db_table: "use_cases",
        bot_name: "FormatBirthdays"
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
      allow(@pg_result).to receive(:values).and_return([[birthdays_results]])
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
    let(:birthdays) do
      [{
        "name" => "John Doe",
        "birthday_date" => "2024-05-01"
      },
       {
         "name" => "Jane Doe",
         "birthday_date" => "2024-05-01"
       }]
    end

    let(:formatted_birthday) do
      " John Doe, Wishing you a very happy birthday! \n Jane Doe, Wishing you a very happy birthday! \n"
    end

    it "returns an empty success hash when the birthdays list is empty" do
      read_response = Read::Types::Response.new({ "birthdays" => [] })

      expect(@bot.process(read_response)).to eq({ success: { notification: "" } })
    end

    it "returns an empty success hash when the record was not found" do
      read_response = Read::Types::Response.new(nil)

      expect(@bot.process(read_response)).to eq({ success: { notification: "" } })
    end

    it "returns a success hash with the list of formatted birthdays" do
      read_response = Read::Types::Response.new({ "birthdays" => birthdays })
      processed = @bot.process(read_response)

      expect(processed).to eq({ success: { notification: formatted_birthday } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:formatted_birthday) do
      " John Doe, Wishing you a very happy birthday! \n Jane Doe, Wishing you a very happy birthday! \n"
    end

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      process_response = { success: { notification: formatted_birthday } }

      expect(@bot.write(process_response)).to_not be_nil
    end
  end
end
