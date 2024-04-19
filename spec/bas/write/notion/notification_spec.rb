# frozen_string_literal: true

RSpec.describe Write::Notion::Notification do
  require "webmock/rspec"

  before do
    @config = {
      secret: "sk-proj-abcdef",
      page_id: "5ba364b113a54c8db0d358bd93754abc",
      timezone: "-05:00"
    }

    choices = [{ "message" => { "role" => "assistant",
                                "content" => "- John Doe:\n  - Out of office for the entire week (15th - 19th April)." } }] # rubocop:disable Layout/LineLength
    openai_response = Process::OpenAI::Types::Response.new({ "choices" => choices })
    @process_response = Process::Types::Response.new(openai_response)

    @write = described_class.new(@config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@write).to respond_to(:execute).with(1).arguments }
    it { expect(@write).to respond_to(:config) }
  end

  describe ".execute" do
    let(:request_body) do
      "{\"properties\":{\"Notification\":{\"rich_text\":[{\"text\":{\"content\":\"- John Doe:\\n  - Out of office for the entire week (15th - 19th April).\"}}]}}}" # rubocop:disable Layout/LineLength
    end
    let(:headers) do
      {
        "Authorization" => "Bearer sk-proj-abcdef",
        "Content-Type" => "application/json",
        "Notion-Version" => "2022-06-28"
      }
    end

    it "writes the notification text in a Notion database" do
      stub_request(:patch, "https://api.notion.com/v1/pages/5ba364b113a54c8db0d358bd93754abc")
        .with(
          body: request_body,
          headers:
        )
        .to_return(status: 200, body: "", headers: {})

      response = @write.execute(@process_response)

      expect(response.code).to eq(200)
    end
  end
end
