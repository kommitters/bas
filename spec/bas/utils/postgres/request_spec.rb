# frozen_string_literal: true

require "bas/utils/postgres/request"

RSpec.describe Utils::Postgres::Request do
  before do
    @params = {
      endpoint: "endpoint",
      secret: "secret",
      method: "get",
      filter: { filter: { property: "name", text: { equal: "John Doe" } } }
    }

    @pg_conn = instance_double(PG::Connection)
    pg_result = instance_double(PG::Result)

    allow(PG::Connection).to receive(:new).and_return(@pg_conn)
    allow(@pg_conn).to receive(:exec_params).and_return(pg_result)
    allow(@pg_conn).to receive(:exec).and_return(pg_result)
  end

  describe ".execute" do
    it { expect(described_class.execute(@params)).to_not be_nil }
  end

  describe ".execute_query" do
    it "execute query when the query is a string" do
      query = "SELECT id FROM users WHERE name='John Doe'"
      response = described_class.execute_query(@pg_conn, query)

      expect(response).to_not be_nil
    end

    it "execute the query when the query is an array" do
      query = ["SELECT id FROM users WHERE name=$1", ["John Doe"]]
      response = described_class.execute_query(@pg_conn, query)

      expect(response).to_not be_nil
    end
  end
end
