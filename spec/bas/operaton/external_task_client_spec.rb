# frozen_string_literal: true

require "spec_helper"
require "bas/utils/operaton/external_task_client"

RSpec.describe Utils::Operaton::ExternalTaskClient do
  let(:base_url) { "http://example.com/engine-rest" }
  let(:worker_id) { "test-worker" }
  subject(:client) { described_class.new(base_url: base_url, worker_id: worker_id) }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:conn) do
    Faraday.new do |b|
      b.adapter(:test, stubs)
      b.request :json
      b.response :json, content_type: /\bjson$/
    end
  end

  before do
    allow_any_instance_of(described_class).to receive(:build_conn).and_return(conn)
  end

  after do
    stubs.verify_stubbed_calls
  end

  describe "#initialize" do
    it "raises an error if base_url is missing" do
      expect do
        described_class.new(worker_id: worker_id,
                            base_url: nil)
      end.to raise_error(ArgumentError, "base_url cannot be nil or empty")
    end

    it "raises an error if worker_id is missing" do
      expect do
        described_class.new(base_url: base_url,
                            worker_id: nil)
      end.to raise_error(ArgumentError, "worker_id cannot be nil or empty")
    end
  end

  describe "#fetch_and_lock" do
    it "sends the correct payload to the fetchAndLock endpoint" do
      topics = "topic1, topic2"
      stubs.post("#{base_url}/external-task/fetchAndLock") do |env|
        payload = JSON.parse(env.body)
        expect(payload["workerId"]).to eq(worker_id)
        expect(payload["maxTasks"]).to eq(1)
        expect(payload["topics"][0]["topicName"]).to eq("topic1")
        expect(payload["topics"][1]["topicName"]).to eq("topic2")
        [200, { "Content-Type" => "application/json" }, '[{"id": "task1"}]']
      end

      tasks = client.fetch_and_lock(topics)
      expect(tasks).to eq([{ "id" => "task1" }])
    end
  end

  describe "#complete" do
    it "sends the correct payload to the complete endpoint" do
      task_id = "task123"
      variables = { customer_name: "John Doe" }

      stubs.post("#{base_url}/external-task/#{task_id}/complete") do |env|
        payload = JSON.parse(env.body)
        expect(payload["workerId"]).to eq(worker_id)
        expect(payload["variables"]["customer_name"]["value"]).to eq("John Doe")
        [204, {}, ""]
      end

      client.complete(task_id, variables)
    end
  end

  describe "#unlock" do
    it "sends a request to the unlock endpoint" do
      task_id = "task123"
      stubs.post("#{base_url}/external-task/#{task_id}/unlock") do
        [204, {}, ""]
      end

      client.unlock(task_id)
    end
  end

  describe "#report_failure" do
    it "sends the correct payload to the failure endpoint" do
      task_id = "task123"
      stubs.post("#{base_url}/external-task/#{task_id}/failure") do |env|
        payload = JSON.parse(env.body)
        expect(payload["workerId"]).to eq(worker_id)
        expect(payload["errorMessage"]).to eq("An error occurred")
        expect(payload["errorDetails"]).to eq("Stack trace...")
        expect(payload["retries"]).to eq(3)
        expect(payload["retryTimeout"]).to eq(5000)
        [204, {}, ""]
      end

      client.report_failure(
        task_id,
        error_message: "An error occurred",
        error_details: "Stack trace...",
        retries: 3,
        retry_timeout: 5000
      )
    end
  end
end
