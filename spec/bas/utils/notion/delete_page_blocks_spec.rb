# frozen_string_literal: true

require "bas/utils/notion/delete_page_blocks"

RSpec.describe Utils::Notion::DeletePageBlocks do
  let(:params) { { page_id: "page_123", secret: "notion_secret" } }
  let(:mock_response) do
    double("http_response", parsed_response: { "results" => [{ "id" => "block_1" }, { "id" => "block_2" }] })
  end

  before do
    allow(Utils::Notion::Request).to receive(:execute).with(hash_including(endpoint: "blocks/page_123/children"))
                                                      .and_return(mock_response)
    allow(Utils::Notion::Request).to receive(:execute).with(hash_including(method: "delete"))
  end

  describe "#execute" do
    it "deletes all blocks from a page" do
      described_class.new(params).execute
      expect(Utils::Notion::Request).to have_received(:execute).with(hash_including(method: "delete")).twice
    end
  end
end
