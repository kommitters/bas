# frozen_string_literal: true

require "bas/write/notion/use_case/empty_notification"
require "bas/process/types/response"
require "httparty"

RSpec.describe Write::Notion::EmptyNotification do
  require "webmock/rspec"

  before do
    @config = {
      secret: "sk-proj-abcdef",
      page_id: "5ba364b113a54c8db0d358bd93754abc"
    }

    httpparty_response = instance_double(HTTParty)
    @process_response = Process::Types::Response.new(httpparty_response)

    @write = described_class.new(@config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@write).to respond_to(:execute).with(1).arguments }
    it { expect(@write).to respond_to(:config) }
  end

  describe ".execute" do
    let(:request_body) do
      "{\"properties\":{\"Notification\":{\"rich_text\":[{\"text\":{\"content\":\"\"}}]}}}"
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
