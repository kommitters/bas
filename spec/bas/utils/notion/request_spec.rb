# frozen_string_literal: true

require "bas/utils/notion/request"

RSpec.describe Utils::Notion::Request do
  let(:params) do
    { endpoint: "endpoint", secret: "secret", method: "get",
      filter: { property: "name", text: { equals: "John Doe" } } }
  end
  let(:response) { double("http_response") }

  before { allow(HTTParty).to receive(:send).and_return(response) }

  describe ".execute" do
    it "executes the request and returns a response" do
      expect(described_class.execute(params)).to eq(response)
    end
  end

  describe ".notion_headers" do
    it "returns the correct headers" do
      expect(described_class.notion_headers(params[:secret])).to eq(
        "Authorization" => "Bearer #{params[:secret]}",
        "Content-Type" => "application/json",
        "Notion-Version" => "2022-06-28"
      )
    end
  end
end
