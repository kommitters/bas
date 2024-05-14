# frozen_string_literal: true

require "bas/utils/notion/request"

RSpec.describe Utils::Notion::Request do
  before do
    @params = {
      endpoint: "endpoint",
      secret: "secret",
      method: "get",
      filter: { filter: { property: "name", text: { equal: "John Doe" } } }
    }
  end

  describe ".execute" do
    let(:response) { double("http_response") }
    before { allow(HTTParty).to receive(:send).and_return(response) }

    it { expect(described_class.execute(@params)).to_not be_nil }
  end

  describe ".notion_headers" do
    it {
      expect(described_class.notion_headers(@params[:secret])).to eq({
                                                                       "Authorization" => "Bearer #{@params[:secret]}",
                                                                       "Content-Type" => "application/json",
                                                                       "Notion-Version" => "2022-06-28"
                                                                     })
    }
  end
end
