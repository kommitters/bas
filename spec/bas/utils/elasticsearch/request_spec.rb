# frozen_string_literal: true

require "bas/utils/elasticsearch/request"

RSpec.describe Utils::Elasticsearch::Request do
  let(:es_client) { instance_double(::Elasticsearch::Client) }
  let(:cluster_client) { instance_double(::Elasticsearch::API::Cluster::Actions) }
  let(:indices_client) { instance_double(::Elasticsearch::API::Indices::Actions) }

  before do
    allow(::Elasticsearch::Client).to receive(:new).and_return(es_client)
    allow(es_client).to receive(:cluster).and_return(cluster_client)
    allow(es_client).to receive(:indices).and_return(indices_client)
    allow(cluster_client).to receive(:health)
  end

  describe ".execute" do
    let(:connection_params) do
      {
        host: "localhost",
        port: 9200,
        user: "elastic",
        password: "changeme",
        ca_file: "/path/to/ca.crt"
      }
    end

    context "when method is :search" do
      let(:search_params) do
        {
          connection: connection_params,
          method: :search,
          index: "my-index"
        }
      end

      it "performs a search with a string query" do
        params = search_params.merge(query: "test query")
        expect(es_client).to receive(:search).with(index: "my-index", size: 1, q: "test query")
        described_class.execute(params)
      end

      it "performs a search with a hash query" do
        query = { query: { match: { title: "test" } } }
        params = search_params.merge(query: query)
        expect(es_client).to receive(:search).with(index: "my-index", size: 1, body: query)
        described_class.execute(params)
      end
    end

    context "when method is :index" do
      it "indexes a document" do
        params = {
          connection: connection_params,
          method: :index,
          index: "my-index",
          body: { title: "Test Title", content: "Test content." }
        }
        expect(es_client).to receive(:index).with(index: "my-index", body: params[:body])
        described_class.execute(params)
      end
    end

    context "when method is :update" do
      it "updates a document" do
        params = {
          connection: connection_params,
          method: :update,
          index: "my-index",
          body: { query: { match: { title: "test" } }, doc: { content: "Updated content." } }
        }
        expect(es_client).to receive(:update_by_query)
          .with(index: "my-index", body: params[:body], wait_for_completion: true, refresh: true)
        described_class.execute(params)
      end
    end

    context "when method is :create_mapping" do
      let(:mapping_params) do
        {
          connection: connection_params,
          method: :create_mapping,
          index: "my-index",
          body: { mappings: { properties: { title: { type: "text" } } } }
        }
      end

      it "creates an index with mapping if it does not exist" do
        allow(indices_client).to receive(:exists?).with(index: "my-index").and_return(false)
        expect(indices_client).to receive(:create).with(index: "my-index", body: mapping_params[:body])
        described_class.execute(mapping_params)
      end

      it "does not create an index if it already exists" do
        allow(indices_client).to receive(:exists?).with(index: "my-index").and_return(true)
        expect(indices_client).not_to receive(:create)
        described_class.execute(mapping_params)
      end
    end
  end
end
