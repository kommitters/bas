# frozen_string_literal: true

require "bas/shared_storage/postgres"
require "bas/shared_storage/types/read"

RSpec.describe Bas::SharedStorage::Postgres do
  let(:connection) { { host: "localhost", port: 5432, dbname: "bas", user: "postgres", password: "postgres" } }
  let(:read_options) { { connection:, db_table: "bas" } }
  let(:write_options) { { connection:, db_table: "bas" } }
  let(:read_response) { Bas::SharedStorage::Types::Read.new }
  let(:process_success_response) { { success: "ok" } }
  let(:process_error_response) { { error: "there was an error" } }

  before do
    @pg_conn = instance_double(PG::Connection)
    pg_result = instance_double(PG::Result)

    allow(PG::Connection).to receive(:new).and_return(@pg_conn)
    allow(@pg_conn).to receive(:exec_params).and_return(pg_result)
    allow(@pg_conn).to receive(:exec).and_return(pg_result)
    allow(pg_result).to receive(:map).and_return([{ id: 1, data: "{ \"success\": \"ok\" }",
                                                    inserted_at: "2024-11-12T00:00:00" }])
  end

  describe ".read" do
    it "search using the default where and params" do
      shared_storage = described_class.new(read_options:, write_options:)

      expect(shared_storage.read).to be_a(Bas::SharedStorage::Types::Read)
      expect(shared_storage.read_response).to be_a(Bas::SharedStorage::Types::Read)
      expect(shared_storage.read_response.id).to eql(1)
      expect(shared_storage.read_response.data).to eql({ "success" => "ok" })
      expect(shared_storage.read_response.inserted_at).to eql("2024-11-12T00:00:00")
    end

    it "search using the configured where and params" do
      options = read_options.merge({ where: "id=$1", params: [2] })
      shared_storage = described_class.new(read_options: options, write_options:)

      expect(shared_storage.read).to be_a(Bas::SharedStorage::Types::Read)
      expect(shared_storage.read_response).to be_a(Bas::SharedStorage::Types::Read)
      expect(shared_storage.read_response.id).to eql(1)
      expect(shared_storage.read_response.data).to eql({ "success" => "ok" })
      expect(shared_storage.read_response.inserted_at).to eql("2024-11-12T00:00:00")
    end
  end

  describe ".write" do
    before { @shared_storage = described_class.new(read_options:, write_options:) }

    it "save a success result" do
      @shared_storage.write(process_success_response)

      expect(@shared_storage.write_response).not_to be(nil)
    end

    it "save an error result" do
      @shared_storage.write(process_error_response)

      expect(@shared_storage.write_response).not_to be(nil)
    end
  end

  describe ".set_in_process" do
    it "ignore execution if avoid_process is set to true" do
      options = read_options.merge({ avoid_process: true })
      shared_storage = described_class.new(read_options: options, write_options:)

      expect(shared_storage.set_in_process).to eql(nil)
    end

    it "update the record status to 'in process'" do
      shared_storage = described_class.new(read_options:, write_options:)

      shared_storage.read

      expect(shared_storage.set_in_process).not_to be(nil)
    end
  end

  describe ".set_processed" do
    it "ignore execution if avoid_process is set to true" do
      options = read_options.merge({ avoid_process: true })
      shared_storage = described_class.new(read_options: options, write_options:)

      expect(shared_storage.set_processed).to eql(nil)
    end

    it "update the record status to 'processed'" do
      shared_storage = described_class.new(read_options:, write_options:)

      shared_storage.read

      expect(shared_storage.set_processed).not_to be(nil)
    end
  end
end
