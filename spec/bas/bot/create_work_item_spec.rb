# frozen_string_literal: true

require "bas/bot/create_work_item"

RSpec.describe Bot::CreateWorkItem do
  before do
    connection = {
      host: "localhost",
      port: 5432,
      dbname: "bas",
      user: "postgres",
      password: "postgres"
    }

    config = {
      read_options: {
        connection:,
        db_table: "github_issues",
        tag: "CreateWorkItemRequest"
      },
      process_options: {
        database_id: "database id",
        secret: "notion secret",
        domain: "domain",
        status: "Backlog",
        work_item_type: "project",
        project: "project_id"
      },
      write_options: {
        connection:,
        db_table: "github_issues",
        tag: "CreateWorkItem"
      }
    }

    @bot = described_class.new(config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }

    it { expect(@bot).to respond_to(:execute).with(0).arguments }
    it { expect(@bot).to respond_to(:read).with(0).arguments }
    it { expect(@bot).to respond_to(:process).with(0).arguments }
    it { expect(@bot).to respond_to(:write).with(0).arguments }

    it { expect(@bot).to respond_to(:read_options) }
    it { expect(@bot).to respond_to(:process_options) }
    it { expect(@bot).to respond_to(:write_options) }
  end

  describe ".read" do
    let(:pg_conn) { instance_double(PG::Connection) }
    let(:issue_result) do
      "{\"issue\":\
      {\"id\": \"12345\", \"body\": \"simple description\",\
      \"state\": \"open\", \"title\": \"Issue\", \"labels\": [],\
       \"html_url\":\"https://github.com/repo/issues\", \"assignees\": [],\
       \"created_at\":\"2024-07-24 20:13:18 UTC\",\
       \"updated_at\":\"2024-07-24 20:36:57 UTC\"}, \"notion_wi\": \"not found\"\
      }"
    end

    let(:formatted_issue) do
      { "issue" => {
        "id" => "12345",
        "body" => "simple description",
        "state" => "open",
        "title" => "Issue",
        "labels" => [],
        "html_url" => "https://github.com/repo/issues",
        "assignees" => [],
        "created_at" => "2024-07-24 20:13:18 UTC",
        "updated_at" => "2024-07-24 20:36:57 UTC"
      }, "notion_wi" => "not found" }
    end

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[1, issue_result, "date"]])
    end

    it "read the notification from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(formatted_issue)
    end
  end

  describe ".process" do
    let(:work_item) { { "id" => "123456789" } }

    let(:issue) do
      {
        "id" => "12345",
        "body" => "simple description",
        "state" => "open",
        "title" => "Issue",
        "labels" => [],
        "html_url" => "https://github.com/repo/issues",
        "assignees" => [],
        "created_at" => "2024-07-24 20:13:18 UTC",
        "updated_at" => "2024-07-24 20:36:57 UTC"
      }
    end

    let(:issue_request) { { "issue" => issue } }
    let(:issue_request_activity) { { "issue" => issue, "work_item_type" => "activity", "type_id": "id" } }
    let(:issue_request_project) { { "issue" => issue, "work_item_type" => "project", "type_id": "id" } }

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    let(:response) { double("http_response") }

    before do
      allow(HTTParty).to receive(:send).and_return(response)
    end

    it "creates a work item on notion and returns its notion id for an activity" do
      @bot.read_response = Read::Types::Response.new(1, issue_request_activity, "date")
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:[]).and_return("123456789")

      processed = @bot.process

      expect(processed).to eq({ success: { issue:, notion_wi: "123456789" } })
    end

    it "creates a work item on notion and returns its notion id for a project" do
      @bot.read_response = Read::Types::Response.new(1, issue_request_project, "date")
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:[]).and_return("123456789")

      processed = @bot.process

      expect(processed).to eq({ success: { issue:, notion_wi: "123456789" } })
    end

    it "returns an error hash with the error message" do
      @bot.read_response = Read::Types::Response.new(1, issue_request, "date")
      allow(response).to receive(:code).and_return(404)
      allow(response).to receive(:parsed_response).and_return(error_response)

      processed = @bot.process

      expect(processed).to eq({ error: { message: error_response, status_code: 404 } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:issue) do
      {
        "id" => "12345",
        "body" => "simple description",
        "state" => "open",
        "title" => "Issue",
        "labels" => [],
        "html_url" => "https://github.com/repo/issues",
        "assignees" => [],
        "created_at" => "2024-07-24 20:13:18 UTC",
        "updated_at" => "2024-07-24 20:36:57 UTC"
      }
    end

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response with 'UpdateWorkItemRequest' tag when it has a notion wi" do
      @bot.process_response = { success: { issue:, notion_wi: "123456789" } }

      expect(@bot.write).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      @bot.process_response = { error: { message: error_response, status_code: 404 } }

      expect(@bot.write).to_not be_nil
    end
  end
end
