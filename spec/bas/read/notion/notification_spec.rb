# frozen_string_literal: true

require "bas/read/notion/use_case/notification"

RSpec.describe Read::Notion::Notification do
  require "webmock/rspec"

  before do
    @config = {
      database_id: "b68d11061aad43bd89f8f525ede2b598",
      secret: "secret_ZELfDH6cf4Glc9NLPLxvsvdl9iZVD4qBCyMDXqch51C",
      use_case_title: "PTO"
    }

    @read = described_class.new(@config)
  end

  describe "attributes and arguments" do
    it { expect(@read).to respond_to(:config) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@read).to respond_to(:execute).with(0).arguments }
  end

  describe ".execute" do
    let(:headers) do
      {
        "Authorization" => "Bearer secret_ZELfDH6cf4Glc9NLPLxvsvdl9iZVD4qBCyMDXqch51C",
        "Content-Type" => "application/json",
        "Notion-Version" => "2022-06-28"
      }
    end

    let(:body) do
      { "object" => "list",
        "results" => [{
          "object" => "page",
          "id" => "4ba384b1-13e5-4c8d-b0d3-58bd93754cfc",
          "created_time" => "2024-01-22T20:27:00.000Z",
          "last_edited_time" => "2024-04-19T21:19:00.000Z",
          "created_by" => { "object" => "user", "id" => "7b6a0839-d5ad-4636-9509-8411cc70688d" },
          "last_edited_by" => { "object" => "user", "id" => "36218f6e-eb2d-47f9-8b56-8faef5dff5cf" },
          "cover" => nil,
          "icon" => nil,
          "parent" => { "type" => "database_id", "database_id" => "bd803082-d13a-469b-8893-67b5bed11f90" },
          "archived" => false,
          "in_trash" => false,
          "properties" => { "Notification" => { "id" => "%40gQ%3B", "type" => "rich_text", "rich_text" => [{ "type" => "text", "text" => { "content" => "", "link" => nil }, "annotations" => { "bold" => false, "italic" => false, "strikethrough" => false, "underline" => false, "code" => false, "color" => "default" }, "plain_text" => "", "href" => nil }] }, "Created time" => { "id" => "Ntch", "type" => "created_time", "created_time" => "2024-01-22T20:27:00.000Z" }, "Type" => { "id" => "s%3Eqc", "type" => "rich_text", "rich_text" => [{ "type" => "text", "text" => { "content" => "pto", "link" => nil }, "annotations" => { "bold" => false, "italic" => false, "strikethrough" => false, "underline" => false, "code" => false, "color" => "default" }, "plain_text" => "pto", "href" => nil }] }, "Use Case" => { "id" => "title", "type" => "title", "title" => [{ "type" => "text", "text" => { "content" => "PTO", "link" => nil }, "annotations" => { "bold" => false, "italic" => false, "strikethrough" => false, "underline" => false, "code" => false, "color" => "default" }, "plain_text" => "PTO", "href" => nil }] } }, "url" => "https://www.notion.so/PTO-4ba384b113e54c8db0d358bd93754cfc", "public_url" => nil # rubocop:disable Layout/LineLength
        }],
        "next_cursor" => nil,
        "has_more" => false,
        "type" => "page_or_database",
        "page_or_database" => {}, "request_id" => "a6e3c577-38a5-43be-8a42-d7cee504afd2" }
    end

    it "read data from the given configured notion database" do
      stub_request(:post, "https://api.notion.com/v1/databases/b68d11061aad43bd89f8f525ede2b598/query")
        .with(
          body: "{\"filter\":{\"property\":\"Use Case\",\"title\":{\"equals\":\"PTO\"}}}",
          headers:
        )
        .to_return_json(status: 200, body:, headers: {})

      read_data = @read.execute

      expect(read_data).to be_an_instance_of(Read::Notion::Types::Response)
      expect(read_data.results).to be_an_instance_of(Array)
      expect(read_data.results.length).to eq(1)
    end
  end
end
