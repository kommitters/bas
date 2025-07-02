# frozen_string_literal: true

require "bas/shared_storage/elasticsearch"
require "bas/shared_storage/types/read"

RSpec.describe Bas::SharedStorage::Elasticsearch do
  let(:connection) { { host: "localhost", port: 9200, user: "elastic", password: "password" } }
  let(:read_options) { { connection:, index: "bas", tag: "my-tag" } }
  let(:write_options) { { connection:, index: "bas", tag: "my-tag" } }
  let(:read_response) { Bas::SharedStorage::Types::Read.new }
  let(:process_success_response) { { success: "ok" } }
  let(:process_error_response) { { error: "there was an error" } }
  let(:es_response_body) do
    {
      "hits" => {
        "hits" => [
          {
            "_id" => "1",
            "_source" => {
              "data" => { "success" => "ok" },
              "inserted_at" => "2024-11-12T00:00:00"
            }
          }
        ]
      }
    }
  end
  let(:es_response) { double("Elasticsearch::Response", body: es_response_body) }

  before do
    allow(Utils::Elasticsearch::Request).to receive(:execute).and_return(es_response)
    allow(es_response).to receive(:[]).with("hits").and_return(es_response_body["hits"])
  end

  describe ".read" do
    it "searches using default query" do
      shared_storage = described_class.new(read_options:, write_options:)

      expect(shared_storage.read).to be_a(Bas::SharedStorage::Types::Read)
      expect(shared_storage.read_response).to be_a(Bas::SharedStorage::Types::Read)
      expect(shared_storage.read_response.id).to eql("1")
      expect(shared_storage.read_response.data).to eql({ "success" => "ok" })
      expect(shared_storage.read_response.inserted_at).to eql("2024-11-12T00:00:00")
    end

    it "searches using a custom query" do
      custom_query = { query: { match_all: {} } }
      options = read_options.merge({ query: custom_query })
      shared_storage = described_class.new(read_options: options, write_options:)

      expect(Utils::Elasticsearch::Request).to receive(:execute).with(
        hash_including(query: custom_query)
      )

      shared_storage.read
    end
  end

  describe ".write" do
    before { @shared_storage = described_class.new(read_options:, write_options:) }

    it "saves a success result" do
      expect(Utils::Elasticsearch::Request).to receive(:execute).twice
      @shared_storage.write(process_success_response)
      expect(@shared_storage.write_response).not_to be_nil
    end

    it "saves an error result" do
      expect(Utils::Elasticsearch::Request).to receive(:execute).twice
      @shared_storage.write(process_error_response)
      expect(@shared_storage.write_response).not_to be_nil
    end
  end

  describe ".set_in_process" do
    it "ignores execution if avoid_process is true" do
      options = read_options.merge({ avoid_process: true })
      shared_storage = described_class.new(read_options: options, write_options:)
      expect(shared_storage.set_in_process).to be_nil
    end

    it "updates the record stage to 'in process'" do
      shared_storage = described_class.new(read_options:, write_options:)
      shared_storage.read
      expect(Utils::Elasticsearch::Request).to receive(:execute).with(
        hash_including(method: :update, id: "1", body: { doc: { stage: "in process" } })
      )
      shared_storage.set_in_process
    end
  end

  describe ".set_processed" do
    it "ignores execution if avoid_process is true" do
      options = read_options.merge({ avoid_process: true })
      shared_storage = described_class.new(read_options: options, write_options:)
      expect(shared_storage.set_processed).to be_nil
    end

    it "updates the record stage to 'processed'" do
      shared_storage = described_class.new(read_options:, write_options:)
      shared_storage.read
      expect(Utils::Elasticsearch::Request).to receive(:execute).with(
        hash_including(method: :update, id: "1", body: { doc: { stage: "processed" } })
      )
      shared_storage.set_processed
    end
  end
end
