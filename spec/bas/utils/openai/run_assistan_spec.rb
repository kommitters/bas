# frozen_string_literal: true

require "bas/utils/openai/run_assistant"

RSpec.describe Utils::OpenAI::RunAssitant do
  let(:params) { { assistant_id: "assistant_id", secret: "openai_secret", prompt: "prompt" } }
  let(:run_response) { double("run_response", parsed_response: { "id" => "run_id", "thread_id" => "thread_id" }) }
  let(:completed_response) { { "status" => "completed", "thread_id" => "thread_id" } }
  let(:failed_response) { { "status" => "failed" } }

  before do
    allow(HTTParty).to receive(:post).and_return(run_response)
    allow(HTTParty).to receive(:get).and_return(completed_response)
  end

  describe "#execute" do
    it "fails when thread and run creation fails" do
      allow(run_response).to receive(:code).and_return(404)
      expect(described_class.execute(params).code).to eq(404)
    end

    it "fails if the poll run fails" do
      allow(run_response).to receive(:code).and_return(200)
      allow(HTTParty).to receive(:get).and_return({ "status" => "in_progress" }, failed_response)

      response = described_class.execute(params)
      expect(response["status"]).to eq("failed")
    end
  end
end
