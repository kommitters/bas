# frozen_string_literal: true

require "bas/utils/notion/update_db_page"

RSpec.describe Utils::Notion::UpdateDatabasePage do
  let(:params) { { page_id: "page_123", secret: "notion_secret", body: { "property" => "value" } } }
  let(:mock_response) { double("http_response") }

  before do
    allow(Utils::Notion::Request).to receive(:execute).and_return(mock_response)
  end

  describe "#execute" do
    it "updates a database page" do
      response = described_class.new(params).execute
      expect(response).to eq(mock_response)
    end
  end
end
