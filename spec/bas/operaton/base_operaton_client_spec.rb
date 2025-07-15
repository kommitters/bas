# frozen_string_literal: true

require "spec_helper"
require "bas/utils/operaton/base_operaton_client"

RSpec.describe Utils::Operaton::BaseClient do
  let(:base_url) { "http://example.com/engine-rest" }
  subject(:client) { described_class.new(base_url: base_url) }
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
    it "raises an error if base_url is nil" do
      expect { described_class.new(base_url: nil) }.to raise_error(ArgumentError, "base_url is required")
    end

    it "raises an error if base_url is empty" do
      expect { described_class.new(base_url: " ") }.to raise_error(ArgumentError, "base_url is required")
    end
  end

  describe "#get" do
    it "makes a GET request and handles a successful response" do
      stubs.get("#{base_url}/test") do
        [200, { "Content-Type" => "application/json" }, '{"status": "ok"}']
      end

      response = client.send(:get, "/test")
      expect(response).to eq({ "status" => "ok" })
    end

    it "raises an error on a failed response" do
      stubs.get("#{base_url}/test") do
        [500, { "Content-Type" => "application/json" }, '{"message": "Internal Server Error"}']
      end

      expect { client.send(:get, "/test") }.to raise_error("Operaton API Error 500: Internal Server Error")
    end
  end

  describe "#post" do
    it "makes a POST request and handles a successful response" do
      stubs.post("#{base_url}/test") do |env|
        expect(JSON.parse(env.body)).to eq({ "key" => "value" })
        [200, { "Content-Type" => "application/json" }, '{"id": "123"}']
      end

      response = client.send(:post, "/test", { key: "value" })
      expect(response).to eq({ "id" => "123" })
    end
  end

  describe "#format_variables" do
    it "converts ruby types to operaton types" do
      vars = {
        a_string: "hello",
        an_integer: 123,
        a_float: 123.45,
        a_boolean: true,
        is_nil: nil,
        an_array: [1, "two"],
        a_hash: { "key" => "value" }
      }

      formatted_vars = client.send(:format_variables, vars)

      expect(formatted_vars[:a_string]).to eq({ value: "hello", type: "String" })
      expect(formatted_vars[:an_integer]).to eq({ value: 123, type: "Integer" })
      expect(formatted_vars[:a_float]).to eq({ value: 123.45, type: "Double" })
      expect(formatted_vars[:a_boolean]).to eq({ value: true, type: "Boolean" })
      expect(formatted_vars[:is_nil]).to eq({ value: nil, type: "Null" })
      expect(formatted_vars[:an_array]).to eq({ value: [1, "two"], type: "Json" })
      expect(formatted_vars[:a_hash]).to eq({ value: { "key" => "value" }, type: "Json" })
    end
  end
end
