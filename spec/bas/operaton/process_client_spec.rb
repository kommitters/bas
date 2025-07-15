# frozen_string_literal: true

require "spec_helper"
require "bas/utils/operaton/process_client"
require "faraday/multipart"

RSpec.describe Utils::Operaton::ProcessClient do
  let(:base_url) { "http://example.com/engine-rest" }
  subject(:client) { described_class.new(base_url: base_url) }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:conn) do
    Faraday.new do |b|
      b.request :multipart
      b.request :url_encoded
      b.adapter(:test, stubs)
      b.response :json, content_type: /\bjson$/
    end
  end

  before do
    allow_any_instance_of(described_class).to receive(:build_conn).and_return(conn)
    # Suppress logger output in tests
    logger = instance_double(Logger, info: nil, warn: nil, error: nil)
    allow(client).to receive(:@logger).and_return(logger)
  end

  after do
    stubs.verify_stubbed_calls
  end

  describe "#deploy_process" do
    let(:file_path) { "/path/to/test.bpmn" }
    let(:deployment_name) { "test-deployment" }

    it "raises an error if the file does not exist" do
      allow(File).to receive(:exist?).with(file_path).and_return(false)
      expect { client.deploy_process(file_path, deployment_name: deployment_name) }
        .to raise_error("File not found: #{file_path}")
    end

    it "raises an error if the file is not readable" do
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(File).to receive(:readable?).with(file_path).and_return(false)
      expect { client.deploy_process(file_path, deployment_name: deployment_name) }
        .to raise_error("File is not readable: #{file_path}")
    end

    it "sends a multipart POST request to the deployment endpoint" do
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(File).to receive(:readable?).with(file_path).and_return(true)
      # Make the mock permissive to avoid conflicts with Faraday's internals
      allow(File).to receive(:basename).and_return("test.bpmn")

      # Use a real FilePart with an in-memory IO object to trigger the multipart middleware
      in_memory_file = Faraday::Multipart::FilePart.new(StringIO.new("<xml></xml>"), "application/octet-stream")
      allow(Faraday::Multipart::FilePart).to receive(:new)
        .with(file_path, "application/octet-stream", "test.bpmn")
        .and_return(in_memory_file)

      stubs.post("#{base_url}/deployment/create") do |env|
        expect(env.request_headers["Content-Type"]).to include("multipart/form-data")
        [200, { "Content-Type" => "application/json" }, '{"id": "dep1"}']
      end

      response = client.deploy_process(file_path, deployment_name: deployment_name)
      expect(response).to eq({ "id" => "dep1" })
    end
  end

  describe "#start_process_instance_by_key" do
    let(:process_key) { "my-process" }
    let(:business_key) { "biz-123" }

    it "sends the correct JSON payload" do
      stubs.post("#{base_url}/process-definition/key/#{process_key}/start") do |env|
        payload = JSON.parse(env.body)
        expect(payload["businessKey"]).to eq(business_key)
        expect(payload["variables"]["amount"]["value"]).to eq(100)
        [200, { "Content-Type" => "application/json" }, '{"id": "inst1"}']
      end

      response = client.start_process_instance_by_key(process_key, business_key: business_key,
                                                                   variables: { amount: 100 })
      expect(response).to eq({ "id" => "inst1" })
    end
  end

  describe "#instance_with_business_key_exists?" do
    let(:process_key) { "my-process" }
    let(:business_key) { "biz-123" }

    it "returns true if an instance with the business key exists" do
      stubs.get("#{base_url}/history/process-instance?processDefinitionKey=#{process_key}&maxResults=50") do
        [200, { "Content-Type" => "application/json" }, '[{"businessKey": "biz-123"}]']
      end

      expect(client.instance_with_business_key_exists?(process_key, business_key)).to be true
    end

    it "returns false if no instance with the business key exists" do
      stubs.get("#{base_url}/history/process-instance?processDefinitionKey=#{process_key}&maxResults=50") do
        [200, { "Content-Type" => "application/json" }, '[{"businessKey": "biz-456"}]']
      end

      expect(client.instance_with_business_key_exists?(process_key, business_key)).to be false
    end
  end
end