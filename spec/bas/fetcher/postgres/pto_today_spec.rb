# frozen_string_literal: true

RSpec.describe Fetcher::Postgres::PtoToday do
  before do
    config = {
      connection: {
        host: "localhost",
        port: 5432,
        dbname: "db_pto",
        user: "postgres",
        password: "postgres"
      }
    }

    @fetcher = described_class.new(config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }

    it { expect(@fetcher).to respond_to(:config) }
    it { expect(@fetcher).to respond_to(:fetch).with(0).arguments }
  end

  describe ".fetch" do
    let(:pg_conn) { instance_double(PG::Connection) }
    let(:fields) { %w[id individual_name start_date end_date] }
    let(:values) { [%w[5 2024-02-13 user1 2024-02-13 2024-02-14]] }

    before do
      @pg_result = double

      allow(@pg_result).to receive(:fields).and_return(fields)
      allow(@pg_result).to receive(:values).and_return(values)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
    end

    it "fetch data from the postgres database when there are results" do
      allow(@pg_result).to receive(:res_status).and_return("PGRES_TUPLES_OK")
      allow(@pg_result).to receive(:check_result).and_return(nil)

      pg_response = @fetcher.fetch

      expect(pg_response.status).to eq("PGRES_TUPLES_OK")
      expect(pg_response.message).to eq("success")
      expect(pg_response.fields).to eq(fields)
      expect(pg_response.records).to eq(values)
    end

    it "fetch data from the postgres database when there are no results" do
      allow(@pg_result).to receive(:fields).and_return([])
      allow(@pg_result).to receive(:values).and_return([])
      allow(@pg_result).to receive(:res_status).and_return("PGRES_TUPLES_OK")
      allow(@pg_result).to receive(:check_result).and_return(nil)

      pg_response = @fetcher.fetch

      expect(pg_response.status).to eq("PGRES_TUPLES_OK")
      expect(pg_response.message).to eq("success")
      expect(pg_response.fields).to eq([])
      expect(pg_response.records).to eq([])
    end

    it "fetch data from the postgres databases with a failure status" do
      allow(@pg_result).to receive(:res_status).and_return("PGRES_EMPTY_QUERY")
      allow(@pg_result).to receive(:result_error_message).and_return("the query is empty")
      allow(@pg_result).to receive(:check_result).and_return(nil)

      pg_response = @fetcher.fetch

      expect(pg_response.status).to eq("PGRES_EMPTY_QUERY")
      expect(pg_response.message).to eq("the query is empty")
      expect(pg_response.fields).to eq(nil)
      expect(pg_response.records).to eq(nil)
    end

    it "fetch data from the postgres databases with a bad state" do
      error_to_raise = PG::Error.new

      allow(@pg_result).to receive(:res_status).and_return("PGRES_BAD_RESPONSE")
      allow(@pg_result).to receive(:result_error_message).and_return("bad response")
      allow(@pg_result).to receive(:check_result).and_raise(error_to_raise)

      expect { @fetcher.fetch }.to raise_exception(error_to_raise)
    end
  end
end
