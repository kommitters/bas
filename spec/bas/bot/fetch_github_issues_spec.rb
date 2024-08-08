# frozen_string_literal: true

require "bas/bot/fetch_github_issues"

RSpec.describe Bot::FetchGithubIssues do
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
        tag: "FetchGithubIssues",
        avoid_process: true
      },
      process_options: {
        private_pem: "private_pem",
        app_id: "app_id",
        repo: "repo",
        filters: { state: "open" }
      },
      write_options: {
        connection:,
        db_table: "github_issues",
        tag: "FetchGithubIssues"
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
    let(:issues_results) do
      "{\"issues\": [\
      {\"id\": \"12345\", \"body\": \"simple description\",\
      \"state\": \"open\", \"title\": \"Issue\", \"labels\": [],\
       \"html_url\":\"https://github.com/repo/issues\", \"assignees\": [],\
       \"created_at\":\"2024-07-24 20:13:18 UTC\",\
       \"updated_at\":\"2024-07-24 20:36:57 UTC\"}\
      ]}"
    end

    let(:formatted_issues) do
      { "issues" => [{
        "id" => "12345",
        "body" => "simple description",
        "state" => "open",
        "title" => "Issue",
        "labels" => [],
        "html_url" => "https://github.com/repo/issues",
        "assignees" => [],
        "created_at" => "2024-07-24 20:13:18 UTC",
        "updated_at" => "2024-07-24 20:36:57 UTC"
      }] }
    end

    before do
      @pg_result = double

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(@pg_result)
      allow(@pg_result).to receive(:values).and_return([[1, issues_results, "date"]])
    end

    it "read the notification from the postgres database" do
      read = @bot.read

      expect(read).to be_a Read::Types::Response
      expect(read.data).to be_a Hash
      expect(read.data).to_not be_nil
      expect(read.data).to eq(formatted_issues)
    end
  end

  describe ".process" do
    let(:issue) do
      double("issue", "id" => "12345",
                      "html_url" => "https://github.com/repo/issues",
                      "title" => "Issue",
                      "body" => "simple description",
                      "labels" => [],
                      "state" => "open",
                      "created_at" => "2024-07-24 20:13:18 UTC",
                      "updated_at" => "2024-07-24 20:13:18 UTC",
                      "assignees" => [])
    end

    let(:issues_results) do
      "{\"issues\": [\
      {\"id\": \"12345\", \"body\": \"simple description\",\
      \"state\": \"open\", \"title\": \"Issue\", \"labels\": [],\
       \"html_url\":\"https://github.com/repo/issues\", \"assignees\": [],\
       \"created_at\":\"2024-07-24 20:13:18 UTC\",\
       \"updated_at\":\"2024-07-24 20:36:57 UTC\"}\
      ]}"
    end

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    let(:pg_conn) { instance_double(PG::Connection) }
    let(:octokit) { double("octokit") }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)

      @bot.read_response = Read::Types::Response.new

      allow(OpenSSL::PKey::RSA).to receive(:new).and_return("private key")
      allow(JWT).to receive(:encode).and_return("jwt")

      allow(octokit).to receive(:create_app_installation_access_token).and_return({ token: "token" })
      allow(octokit).to receive(:find_organization_installation).and_return(double(id: 12_345))
      allow(octokit).to receive(:issues).and_return([issue])
    end

    it "returns a success hash with the list of formatted GitHub issues" do
      allow(Octokit::Client).to receive(:new).and_return(octokit)

      processed = @bot.process

      expect(processed).to eq({ success: { created: true } })
    end

    it "returns a success hash with the list of formatted birthdays" do
      allow(Octokit::Client).to receive(:new).and_return(octokit)

      @bot.read_response = Read::Types::Response.new(1, issues_results, "date")

      processed = @bot.process

      expect(processed).to eq({ success: { created: true } })
    end

    it "returns an error hash with the error message" do
      allow(Octokit::Client).to receive(:new).and_raise(StandardError)

      processed = @bot.process

      expect(processed).to eq({ error: "StandardError" })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:formatted_issues) do
      {
        id: "12345",
        assignees: [],
        html_url: "https://github.com/repo/issues",
        title: "Issue",
        body: "simple description",
        labels: [],
        state: "open",
        created_at: "2024-07-24 20:13:18 UTC",
        updated_at: "2024-07-24 20:13:18 UTC"
      }
    end

    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      @bot.process_response = { success: { issues: [formatted_issues] } }

      expect(@bot.write).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      @bot.process_response = { error: { message: error_response, status_code: 404 } }

      expect(@bot.write).to_not be_nil
    end
  end
end
