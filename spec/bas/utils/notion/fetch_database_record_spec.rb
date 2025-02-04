# frozen_string_literal: true

require "bas/utils/notion/fetch_database_record"

RSpec.describe Utils::Notion::FetchDatabaseRecord do
  let(:params) { { database_id: "db_123", secret: "notion_secret", body: {} } }
  let(:mock_response) { double("http_response", parsed_response: { "results" => [{ "id" => "record_1" }] }) }

  before do
    allow(Utils::Notion::Request).to receive(:execute).and_return(mock_response)
  end

  describe "#execute" do
    it "fetches records from a database" do
      records = described_class.new(params).execute
      expect(records).to eq([{ "id" => "record_1" }])
    end
  end
end
