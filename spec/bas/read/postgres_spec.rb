# frozen_string_literal: true

require "bas/read/postgres"

RSpec.describe Read::Postgres do
  before do
    config = {
      connection: {
        host: "localhost",
        port: 5432,
        dbname: "bas",
        user: "postgres",
        password: "postgres"
      }
    }

    @reader = described_class.new(config)
  end

  describe ".execute" do
    let(:pg_conn) { instance_double(PG::Connection) }
    let(:failes_result) { [] }
    let(:success_result) do
      [[1, "{\"ptos\": [{\"Name\": \"John Doe\", \"EndDateTime\": \
      {\"to\": null, \"from\": \"2024-05-01\"}, \"StartDateTime\": \
      {\"to\": null, \"from\": \"2024-05-01\"}}]}", "date"]]
    end

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
    end

    it "read failed data from the postgres database" do
      allow(@pg_result).to receive(:values).and_return(failes_result)

      pg_response = @reader.execute

      expect(pg_response).to be_a Read::Types::Response
      expect(pg_response.data).to be_nil
    end

    it "read success data from the postgres database" do
      allow(@pg_result).to receive(:values).and_return(success_result)

      pg_response = @reader.execute

      expect(pg_response).to be_a Read::Types::Response
      expect(pg_response.data).to be_a Hash
      expect(pg_response.data).to_not be_nil
    end
  end
end
