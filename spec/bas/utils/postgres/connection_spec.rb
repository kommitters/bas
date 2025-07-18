# frozen_string_literal: true

require "bas/utils/postgres/connection"

RSpec.describe Utils::Postgres::Connection do
  let(:connection_params) do
    {
      host: "localhost",
      port: 5432,
      dbname: "test_db",
      user: "test_user",
      password: "test_password"
    }
  end

  let(:pg_connection) { instance_double(PG::Connection) }
  let(:pg_result) { instance_double(PG::Result) }

  before do
    allow(PG::Connection).to receive(:new).and_return(pg_connection)
    allow(pg_connection).to receive(:exec).and_return(pg_result)
    allow(pg_connection).to receive(:exec_params).and_return(pg_result)
    allow(pg_connection).to receive(:finish)

    # Mock the PG::Result to actually transform keys to symbols when map is called
    allow(pg_result).to receive(:map) do
      # Simulate the actual behavior where each result hash gets its keys transformed to symbols
      raw_data = [
        { "id" => "1", "name" => "John Doe", "email" => "john@example.com" },
        { "id" => "2", "name" => "Jane Smith", "email" => "jane@example.com" }
      ]
      raw_data.map { |result| result.transform_keys(&:to_sym) }
    end
  end

  describe ".new" do
    it "creates a new connection with the provided parameters" do
      expect(PG::Connection).to receive(:new).with(connection_params).and_return(pg_connection)

      described_class.new(connection_params)
    end

    it "raises an error when connection parameters are invalid" do
      allow(PG::Connection).to receive(:new).and_raise(PG::ConnectionBad, "connection failed")

      expect do
        described_class.new({ connection: connection_params })
      end.to raise_error(PG::ConnectionBad, "connection failed")
    end
  end

  describe "#query" do
    let(:connection) { described_class.new({ connection: connection_params }) }

    context "with a string query" do
      let(:query_string) { "SELECT * FROM users WHERE active = true" }
      let(:raw_results) do
        [
          { "id" => "1", "name" => "John Doe", "email" => "john@example.com" },
          { "id" => "2", "name" => "Jane Smith", "email" => "jane@example.com" }
        ]
      end

      before do
        allow(pg_result).to receive(:map).and_return(raw_results.map { |result| result.transform_keys(&:to_sym) })
      end

      it "executes a string query using exec" do
        expect(pg_connection).to receive(:exec).with(query_string).and_return(pg_result)

        result = connection.query(query_string)

        expect(result).to eq([
                               { id: "1", name: "John Doe", email: "john@example.com" },
                               { id: "2", name: "Jane Smith", email: "jane@example.com" }
                             ])
      end

      it "transforms result keys to symbols" do
        result = connection.query(query_string)

        expect(result.first.keys).to all(be_a(Symbol))
        expect(result.first).to have_key(:id)
        expect(result.first).to have_key(:name)
        expect(result.first).to have_key(:email)
      end

      it "handles empty results" do
        allow(pg_result).to receive(:map).and_return([])

        result = connection.query(query_string)

        expect(result).to eq([])
      end
    end

    context "with a parameterized query" do
      let(:query_array) { ["SELECT * FROM users WHERE id = $1 AND active = $2", [1, true]] }
      let(:raw_results) do
        [
          { "id" => "1", "name" => "John Doe", "email" => "john@example.com" }
        ]
      end

      before do
        allow(pg_result).to receive(:map).and_return(raw_results.map { |result| result.transform_keys(&:to_sym) })
      end

      it "executes a parameterized query using exec_params" do
        sentence, params = query_array
        expect(pg_connection).to receive(:exec_params).with(sentence, params).and_return(pg_result)

        result = connection.query(query_array)

        expect(result).to eq([
                               { id: "1", name: "John Doe", email: "john@example.com" }
                             ])
      end

      it "transforms result keys to symbols for parameterized queries" do
        result = connection.query(query_array)

        expect(result.first.keys).to all(be_a(Symbol))
        expect(result.first).to have_key(:id)
        expect(result.first).to have_key(:name)
        expect(result.first).to have_key(:email)
      end

      it "handles parameterized queries with multiple parameters" do
        complex_query = ["SELECT * FROM users WHERE age > $1 AND city = $2 AND active = $3", [18, "New York", true]]
        allow(pg_connection).to receive(:exec_params).and_return(pg_result)

        connection.query(complex_query)

        expect(pg_connection).to have_received(:exec_params).with(complex_query[0], complex_query[1])
      end
    end

    context "error handling" do
      it "raises an error when exec fails" do
        allow(pg_connection).to receive(:exec).and_raise(PG::Error, "syntax error")

        expect do
          connection.query("INVALID SQL")
        end.to raise_error(PG::Error, "syntax error")
      end

      it "raises an error when exec_params fails" do
        allow(pg_connection).to receive(:exec_params).and_raise(PG::Error, "parameter error")

        expect do
          connection.query(["SELECT * FROM users WHERE id = $1", ["invalid"]])
        end.to raise_error(PG::Error, "parameter error")
      end

      it "raises an error when query parameter is neither string nor array" do
        allow(pg_result).to receive(:map).and_raise(NoMethodError, "undefined method")

        expect do
          connection.query(123)
        end.to raise_error(ArgumentError)
      end

      it "raises ArgumentError for parameterized query with wrong array size" do
        expect do
          connection.query(["SELECT * FROM users WHERE id = $1"])
        end.to raise_error(ArgumentError, "Parameterized query must be an array of [sentence (String), params (Array)]")
      end

      it "raises ArgumentError for parameterized query with non-string sentence" do
        expect do
          connection.query([1, [1]])
        end.to raise_error(ArgumentError, "Parameterized query must be an array of [sentence (String), params (Array)]")
      end

      it "raises ArgumentError for parameterized query with non-array params" do
        expect do
          connection.query(["SELECT * FROM users WHERE id = $1", 1])
        end.to raise_error(ArgumentError, "Parameterized query must be an array of [sentence (String), params (Array)]")
      end
    end
  end

  describe "#finish" do
    let(:connection) { described_class.new({ connection: connection_params }) }

    it "closes the underlying PG connection" do
      expect(pg_connection).to receive(:finish)

      connection.finish
    end

    it "sets the connection to nil after closing" do
      connection.finish

      # We can't directly test the instance variable, but we can test that
      # subsequent calls to finish don't raise errors
      expect { connection.finish }.not_to raise_error
    end

    it "handles finish when connection is already closed" do
      connection.finish

      # Should not raise an error when called again
      expect { connection.finish }.not_to raise_error
    end

    it "handles finish when connection is nil" do
      # Simulate a connection that was never established
      allow(PG::Connection).to receive(:new).and_return(nil)

      connection = described_class.new({ connection: connection_params })
      expect { connection.finish }.not_to raise_error
    end
  end

  describe "integration scenarios" do
    let(:connection) { described_class.new({ connection: connection_params }) }

    it "can execute multiple queries on the same connection" do
      allow(pg_connection).to receive(:exec).and_return(pg_result)
      allow(pg_result).to receive(:map).and_return([{ count: "5" }])

      # First query
      result1 = connection.query("SELECT COUNT(*) FROM users")
      expect(result1).to eq([{ count: "5" }])

      # Second query
      result2 = connection.query("SELECT COUNT(*) FROM posts")
      expect(result2).to eq([{ count: "5" }])

      # Verify both queries were executed
      expect(pg_connection).to have_received(:exec).with("SELECT COUNT(*) FROM users")
      expect(pg_connection).to have_received(:exec).with("SELECT COUNT(*) FROM posts")
    end

    it "can execute mixed string and parameterized queries" do
      allow(pg_connection).to receive(:exec).and_return(pg_result)
      allow(pg_connection).to receive(:exec_params).and_return(pg_result)
      allow(pg_result).to receive(:map).and_return([{ result: "success" }])

      # String query
      connection.query("SELECT * FROM users")

      # Parameterized query
      connection.query(["SELECT * FROM users WHERE id = $1", [1]])

      expect(pg_connection).to have_received(:exec).with("SELECT * FROM users")
      expect(pg_connection).to have_received(:exec_params).with("SELECT * FROM users WHERE id = $1", [1])
    end

    it "properly closes connection after use" do
      allow(pg_connection).to receive(:exec).and_return(pg_result)
      allow(pg_result).to receive(:map).and_return([])

      connection.query("SELECT * FROM users")
      connection.finish

      expect(pg_connection).to have_received(:finish)
    end
  end

  describe "edge cases" do
    let(:connection) { described_class.new({ connection: connection_params }) }

    it "handles queries with special characters" do
      special_query = "SELECT * FROM users WHERE name LIKE '%test%' AND email ~ '^[a-z]+@[a-z]+\\.com$'"
      allow(pg_connection).to receive(:exec).and_return(pg_result)
      allow(pg_result).to receive(:map).and_return([])

      connection.query(special_query)

      expect(pg_connection).to have_received(:exec).with(special_query)
    end

    it "handles parameterized queries with null values" do
      null_query = ["SELECT * FROM users WHERE name = $1 AND email = $2", ["John", nil]]
      allow(pg_connection).to receive(:exec_params).and_return(pg_result)
      allow(pg_result).to receive(:map).and_return([])

      connection.query(null_query)

      expect(pg_connection).to have_received(:exec_params).with(null_query[0], null_query[1])
    end

    it "handles queries with empty string parameters" do
      empty_query = ["SELECT * FROM users WHERE name = $1", [""]]
      allow(pg_connection).to receive(:exec_params).and_return(pg_result)
      allow(pg_result).to receive(:map).and_return([])

      connection.query(empty_query)

      expect(pg_connection).to have_received(:exec_params).with(empty_query[0], empty_query[1])
    end

    it "handles results with complex data types" do
      complex_results = [
        { "id" => "1", "data" => "{\"key\": \"value\"}", "array" => "{1,2,3}", "timestamp" => "2024-01-01 12:00:00" }
      ]
      allow(pg_connection).to receive(:exec).and_return(pg_result)
      allow(pg_result).to receive(:map).and_return(complex_results.map { |result| result.transform_keys(&:to_sym) })

      result = connection.query("SELECT * FROM complex_table")

      expect(result.first).to eq({
                                   id: "1",
                                   data: "{\"key\": \"value\"}",
                                   array: "{1,2,3}",
                                   timestamp: "2024-01-01 12:00:00"
                                 })
    end
  end
end
