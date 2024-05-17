# frozen_string_literal: true

require "bas/bot/compare_wip_limit_count"

RSpec.describe Bot::CompareWipLimitCount do
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
        tag: "FetchDomainsWipLimitFromNotion"
      },
      write_options: {
        connection:,
        db_table: "use_cases",
        tag: "CompareWipLimitCount"
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
    let(:domains_wip_limit_counts_results) do
      "{\"domains_limits\": {\"ops\": 1, \"engineering\": 1}, \"domain_wip_count\": {\"ops\": 1, \"engineering\": 2}}"
    end

    let(:formatted_domains_wip_limit_counts) do
      {
        "domains_limits" => { "ops" => 1, "engineering" => 1 }, "domain_wip_count" => { "ops" => 1, "engineering" => 2 }
      }
    end

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[1, domains_wip_limit_counts_results, "date"]])
    end

    it "read the wip's count and limits by domain from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(formatted_domains_wip_limit_counts)
    end
  end

  describe ".process" do
    let(:formatted_domains_wip_limit_counts) do
      {
        "domains_limits" => { "ops" => 1, "engineering" => 1 }, "domain_wip_count" => { "ops" => 1, "engineering" => 2 }
      }
    end

    let(:exceeded_domain_count) { [{ domain: "engineering", exceeded: 1 }] }

    it "returns an empty success hash when the record was not found" do
      @bot.read_response = Read::Types::Response.new(nil)

      expect(@bot.process).to eq({ success: { exceeded_domain_count: {} } })
    end

    it "returns an empty success hash when the limits count hash is empty" do
      @bot.read_response = Read::Types::Response.new({})

      expect(@bot.process).to eq({ success: { exceeded_domain_count: {} } })
    end

    it "returns an empty success hash when the domains_limits list is empty" do
      @bot.read_response = Read::Types::Response.new({ "domains_limits" => [] })

      expect(@bot.process).to eq({ success: { exceeded_domain_count: {} } })
    end

    it "returns an empty success hash when the domain_wip_count list is empty" do
      @bot.read_response = Read::Types::Response.new({ "domains_limits" => [{}], "domain_wip_count" => [] })

      expect(@bot.process).to eq({ success: { exceeded_domain_count: {} } })
    end

    it "returns a success hash with the hash of wip limits counts" do
      @bot.read_response = Read::Types::Response.new(1, formatted_domains_wip_limit_counts, "date")
      processed = @bot.process

      expect(processed).to eq({ success: { exceeded_domain_count: } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:exceeded_domain_count) { [{ domain: "engineering", exceeded: 1 }] }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      @bot.process_response = { success: { exceeded_domain_count: } }

      expect(@bot.write).to_not be_nil
    end
  end
end
