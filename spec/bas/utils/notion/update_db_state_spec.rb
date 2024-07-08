# frozen_string_literal: true

require "bas/utils/notion/update_db_state"

RSpec.describe Utils::Notion::UpdateDbState do
  before do
    @data = {
      property: "text",
      page_id: "abcd1234",
      state: "in process",
      secret: "notion_secret"
    }
  end

  describe ".execute" do
    let(:response) { double("http_response") }
    before { allow(HTTParty).to receive(:send).and_return(response) }

    it { expect(described_class.execute(@data)).to_not be_nil }
  end

  describe ".build_params" do
    it {
      expect(described_class.build_params(@data)).to eq({
                                                          endpoint: "pages/abcd1234",
                                                          secret: "notion_secret",
                                                          method: "patch", body: {
                                                            properties: { "text" => { select: { name: "in process" } } }
                                                          }
                                                        })
    }
  end

  describe ".body" do
    it {
      expect(described_class.body(@data)).to eq({ properties: { "text" => { select: { name: "in process" } } } })
    }
  end
end
