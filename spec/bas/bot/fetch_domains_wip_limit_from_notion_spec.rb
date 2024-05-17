# frozen_string_literal: true

require "bas/bot/fetch_domains_wip_limit_from_notion"

RSpec.describe Bot::FetchDomainsWipLimitFromNotion do
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
        tag: "FetchDomainsWipCountsFromNotion"
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
        tag: "FetchDomainsWipLimitFromNotion"
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
    let(:wip_count_results) { "{\"domain_wip_count\": {\"kommit.ops\": 7, \"kommit.engineering\": 11}}" }
    let(:formatted_wip_count) { { "domain_wip_count" => { "kommit.ops" => 7, "kommit.engineering" => 11 } } }

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[1, wip_count_results, "date"]])
    end

    it "read the domains wip counts from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(formatted_wip_count)
    end
  end

  describe ".process" do
    let(:domain_limits) do
      [
        { "properties" => { "Name" => { "title" => [{ "plain_text" => "ops" }] },
                            "WIP + On Hold limit" => { "number" => 1 } } },
        { "properties" => { "Name" => { "title" => [{ "plain_text" => "marketing" }] },
                            "WIP + On Hold limit" => { "number" => 1 } } },
        { "properties" => { "Name" => { "title" => [{ "plain_text" => "engineering" }] },
                            "WIP + On Hold limit" => { "number" => 1 } } }
      ]
    end

    let(:domains_wip_count) { { "domain_wip_count" => { "ops" => 1, "marketing" => 1, "engineering" => 2 } } }
    let(:formatted_domain_wip_limits_counts) do
      { domains_limits: { "ops" => 1, "marketing" => 1, "engineering" => 1 } }.merge(domains_wip_count)
    end
    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }
    let(:response) { double("http_response") }

    before do
      @bot.read_response = Read::Types::Response.new(1, domains_wip_count, "date")

      allow(HTTParty).to receive(:send).and_return(response)
    end

    it "returns a success hash with the wip's count and limits by domain" do
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:parsed_response).and_return({ "results" => domain_limits })

      processed = @bot.process

      expect(processed).to eq({ success: formatted_domain_wip_limits_counts })
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

    let(:domains_wip_count) { { "domain_wip_count" => { "ops" => 1, "marketing" => 1, "engineering" => 2 } } }
    let(:formatted_domain_wip_limits_counts) do
      { domains_limits: { "ops" => 1, "marketing" => 1, "engineering" => 1 } }.merge(domains_wip_count)
    end
    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      @bot.process_response = { success: formatted_domain_wip_limits_counts }

      expect(@bot.write).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      @bot.process_response = { error: { message: error_response, status_code: 404 } }

      expect(@bot.write).to_not be_nil
    end
  end
end
