# frozen_string_literal: true

require "bas/shared_storage/postgres"
require "bas/shared_storage/types/read"

RSpec.describe Bas::SharedStorage::Postgres do
  let(:connection_params) { { host: "localhost", port: 5432, dbname: "bas", user: "postgres", password: "postgres" } }
  let(:read_options) { { connection: connection_params, db_table: "bas", tag: "test-tag" } }
  let(:write_options) { { connection: connection_params, db_table: "bas", tag: "test-tag" } }
  let(:read_response) { Bas::SharedStorage::Types::Read.new }
  let(:process_success_response) { { success: "ok" } }
  let(:process_error_response) { { error: "there was an error" } }

  let(:pg_connection) { instance_double(Utils::Postgres::Connection) }
  let(:query_result) { [{ id: 1, data: '{ "success": "ok" }', inserted_at: "2024-11-12T00:00:00" }] }

  before do
    allow(Utils::Postgres::Connection).to receive(:new).and_return(pg_connection)
    allow(pg_connection).to receive(:query).and_return(query_result)
    allow(pg_connection).to receive(:finish)
  end

  describe ".read" do
    it "searches using the default where and params" do
      shared_storage = described_class.new(read_options:, write_options:)

      expect(shared_storage.read).to be_a(Bas::SharedStorage::Types::Read)
      expect(shared_storage.read_response).to be_a(Bas::SharedStorage::Types::Read)
      expect(shared_storage.read_response.id).to eql(1)
      expect(shared_storage.read_response.data).to eql({ "success" => "ok" })
      expect(shared_storage.read_response.inserted_at).to eql("2024-11-12T00:00:00")
    end

    it "searches using the configured where and params" do
      options = read_options.merge({ where: "id=$1", params: [2] })
      shared_storage = described_class.new(read_options: options, write_options:)

      expect(shared_storage.read).to be_a(Bas::SharedStorage::Types::Read)
      expect(shared_storage.read_response).to be_a(Bas::SharedStorage::Types::Read)
      expect(shared_storage.read_response.id).to eql(1)
      expect(shared_storage.read_response.data).to eql({ "success" => "ok" })
      expect(shared_storage.read_response.inserted_at).to eql("2024-11-12T00:00:00")
    end

    it "reuses the read connection for multiple reads" do
      shared_storage = described_class.new(read_options:, write_options:)

      expect(Utils::Postgres::Connection).to receive(:new).once.and_return(pg_connection)

      shared_storage.read
      shared_storage.read # Second call should reuse connection
    end

    it "handles empty query results" do
      allow(pg_connection).to receive(:query).and_return([])
      shared_storage = described_class.new(read_options:, write_options:)

      expect(shared_storage.read).to be_a(Bas::SharedStorage::Types::Read)
      expect(shared_storage.read_response.id).to be_nil
      expect(shared_storage.read_response.data).to eql({})
      expect(shared_storage.read_response.inserted_at).to be_nil
    end
  end

  describe ".write" do
    before { @shared_storage = described_class.new(read_options:, write_options:) }

    it "saves a success result" do
      @shared_storage.write(process_success_response)

      expect(@shared_storage.write_response).not_to be_nil
    end

    it "saves an error result" do
      @shared_storage.write(process_error_response)

      expect(@shared_storage.write_response).not_to be_nil
    end

    it "reuses the write connection for multiple writes" do
      expect(Utils::Postgres::Connection).to receive(:new).once.and_return(pg_connection)

      @shared_storage.write(process_success_response)
      @shared_storage.write(process_error_response) # Second call should reuse connection
    end

    it "uses separate connections for read and write when connection params differ" do
      different_write_options = { connection: connection_params.merge(dbname: "different_db"), db_table: "bas",
                                  tag: "test-tag" }
      shared_storage = described_class.new(read_options:, write_options: different_write_options)

      expect(Utils::Postgres::Connection).to receive(:new).with(read_options[:connection]).once
      expect(Utils::Postgres::Connection).to receive(:new).with(different_write_options[:connection]).once

      shared_storage.read
      shared_storage.write(process_success_response)
    end
  end

  describe ".close_connections" do
    it "closes both read and write connections" do
      shared_storage = described_class.new(read_options:, write_options:)

      # Establish connections
      shared_storage.read
      shared_storage.write(process_success_response)

      expect(pg_connection).to receive(:finish).twice

      shared_storage.close_connections
    end

    it "handles closing connections when none are established" do
      shared_storage = described_class.new(read_options:, write_options:)

      expect { shared_storage.close_connections }.not_to raise_error
    end

    it "allows re-establishing connections after closing" do
      shared_storage = described_class.new(read_options:, write_options:)

      # First connection
      shared_storage.read
      shared_storage.close_connections

      # Should create new connection
      expect(Utils::Postgres::Connection).to receive(:new).and_return(pg_connection)
      shared_storage.read
    end
  end

  describe ".set_in_process" do
    it "ignores execution if avoid_process is set to true" do
      options = read_options.merge({ avoid_process: true })
      shared_storage = described_class.new(read_options: options, write_options:)

      expect(shared_storage.set_in_process).to be_nil
    end

    it "ignores execution if read_response.id is nil" do
      allow(pg_connection).to receive(:query).and_return([])
      shared_storage = described_class.new(read_options:, write_options:)
      shared_storage.read

      expect(shared_storage.set_in_process).to be_nil
    end

    it "updates the record stage to 'in process'" do
      shared_storage = described_class.new(read_options:, write_options:)
      shared_storage.read

      expect(pg_connection).to receive(:query).with(["UPDATE bas SET stage=$1 WHERE id=$2", ["in process", 1]])
      shared_storage.set_in_process
    end

    it "reuses the read connection for updates" do
      shared_storage = described_class.new(read_options:, write_options:)

      # Should only create one connection (for read, then reused for update)
      expect(Utils::Postgres::Connection).to receive(:new).once.and_return(pg_connection)

      shared_storage.read
      shared_storage.set_in_process
    end
  end

  describe ".set_processed" do
    it "ignores execution if avoid_process is set to true" do
      options = read_options.merge({ avoid_process: true })
      shared_storage = described_class.new(read_options: options, write_options:)

      expect(shared_storage.set_processed).to be_nil
    end

    it "ignores execution if read_response.id is nil" do
      allow(pg_connection).to receive(:query).and_return([])
      shared_storage = described_class.new(read_options:, write_options:)
      shared_storage.read

      expect(shared_storage.set_processed).to be_nil
    end

    it "updates the record stage to 'processed'" do
      shared_storage = described_class.new(read_options:, write_options:)
      shared_storage.read

      expect(pg_connection).to receive(:query).with(["UPDATE bas SET stage=$1 WHERE id=$2", ["processed", 1]])
      shared_storage.set_processed
    end

    it "reuses the read connection for updates" do
      shared_storage = described_class.new(read_options:, write_options:)

      # Should only create one connection (for read, then reused for update)
      expect(Utils::Postgres::Connection).to receive(:new).once.and_return(pg_connection)

      shared_storage.read
      shared_storage.set_processed
    end
  end

  describe "connection optimization" do
    it "creates separate connections for read and write operations" do
      shared_storage = described_class.new(read_options:, write_options:)

      # Should create two separate connections
      expect(Utils::Postgres::Connection).to receive(:new).with(connection_params).twice.and_return(pg_connection)

      shared_storage.read
      shared_storage.write(process_success_response)
    end

    it "reuses connections across multiple operations" do
      shared_storage = described_class.new(read_options:, write_options:)

      # Should only create connections once
      expect(Utils::Postgres::Connection).to receive(:new).twice.and_return(pg_connection)

      shared_storage.read
      shared_storage.set_in_process
      shared_storage.write(process_success_response)
      shared_storage.read
      shared_storage.set_processed
    end
  end
end
