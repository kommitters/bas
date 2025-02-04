# frozen_string_literal: true

require "bas/utils/notion/update_db_state"

RSpec.describe Utils::Notion::UpdateDbState do
  let(:data) { { property: "text", page_id: "abcd1234", state: "in process", secret: "notion_secret" } }
  let(:response) { double("http_response") }

  before { allow(HTTParty).to receive(:send).and_return(response) }

  describe ".execute" do
    it "executes the update request and returns a response" do
      expect(described_class.execute(data)).to eq(response)
    end
  end
end
