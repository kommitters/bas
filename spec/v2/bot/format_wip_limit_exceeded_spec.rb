# frozen_string_literal: true

require "v2/bot/format_wip_limit_exceeded"

RSpec.describe Bot::FormatWipLimitExceeded do
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
        bot_name: "CompareWipLimitCount"
      },
      process_options: {
        template: ":warning: The <domain> WIP limit was exceeded by <exceeded>"
      },
      write_options: {
        connection:,
        db_table: "use_cases",
        bot_name: "FormatWipLimitExceeded"
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
    let(:exceedded_wip_limit_results) do
      "{\"exceeded_domain_count\": [{\"domain\": \"engineering\", \"exceeded\": 1}]}"
    end

    let(:formatted_exceedded_wip_limit) do
      { "exceeded_domain_count" => [{ "domain" => "engineering", "exceeded" => 1 }] }
    end

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[exceedded_wip_limit_results]])
    end

    it "read the exceeded wip counts by domain from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(formatted_exceedded_wip_limit)
    end
  end

  describe ".process" do
    let(:exceedded_wip_limit) do
      [{ "domain" => "engineering", "exceeded" => 1 }]
    end

    let(:formatted_exceedded_wip_limit) { " :warning: The engineering WIP limit was exceeded by 1 \n" }

    it "returns an empty success hash when the record was not found" do
      read_response = Read::Types::Response.new(nil)

      expect(@bot.process(read_response)).to eq({ success: { notification: "" } })
    end

    it "returns an empty success hash when the exceeded_domain_count hash is empty" do
      read_response = Read::Types::Response.new({ "exceeded_domain_count" => {} })

      expect(@bot.process(read_response)).to eq({ success: { notification: "" } })
    end

    it "returns a success hash with the list of formatted exceeded domain count" do
      read_response = Read::Types::Response.new({ "exceeded_domain_count" => exceedded_wip_limit })
      processed = @bot.process(read_response)

      expect(processed).to eq({ success: { notification: formatted_exceedded_wip_limit } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:formatted_exceedded_wip_limit) { " :warning: The engineering WIP limit was exceeded by 1 \n" }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      process_response = { success: { notification: formatted_exceedded_wip_limit } }

      expect(@bot.write(process_response)).to_not be_nil
    end
  end
end
