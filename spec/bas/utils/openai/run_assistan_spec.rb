# frozen_string_literal: true

require "bas/utils/openai/run_assistant"

RSpec.describe Utils::OpenAI::RunAssitant do
  let(:params) { { assistant_id: "assistant_id", secret: "openai_secret", prompt: "prompt" } }
  let(:run_response) do
    double("run_response", parsed_response: { "id" => "run_id", "thread_id" => "thread_id" }, code: 200)
  end
  let(:completed_response) { { "status" => "completed", "thread_id" => "thread_id" } }
  let(:messages_response) { { "data" => [{ "content" => "response_message" }] } }

  before do
    allow(HTTParty).to receive(:post).and_return(run_response)
    allow(HTTParty).to receive(:get).and_return(completed_response)
  end

  describe "#execute" do
    context "when thread and run creation fails" do
      it "returns the failed response" do
        allow(run_response).to receive(:code).and_return(404)
        response = described_class.execute(params)
        expect(response.code).to eq(404)
      end
    end

    context "when thread and run creation succeeds" do
      before do
        allow(run_response).to receive(:code).and_return(200)
      end

      context "when poll_run succeeds" do
        it "returns the list of messages" do
          allow(HTTParty).to receive(:get).and_return(completed_response, messages_response)
          response = described_class.execute(params)
          expect(response).to eq(messages_response)
        end
      end

      context "when poll_run fails" do
        it "returns the failed response" do
          allow(HTTParty).to receive(:get).and_return({ "status" => "in_progress" }, { "status" => "failed" })
          response = described_class.execute(params)
          expect(response["status"]).to eq("failed")
        end
      end

      context "when poll_run is in progress" do
        it "polls until completion" do
          allow(HTTParty).to receive(:get).and_return(
            { "status" => "queued" },
            { "status" => "in_progress" },
            completed_response,
            messages_response
          )
          response = described_class.execute(params)
          expect(response).to eq(messages_response)
        end
      end
    end
  end

  describe "#create_thread_and_run" do
    it "sends a POST request to create a thread and run" do
      expect(HTTParty).to receive(:post).with(
        "https://api.openai.com/v1/threads/runs",
        { body: described_class.body, headers: described_class.headers }
      )
      described_class.create_thread_and_run
    end
  end

  describe "#list_messages" do
    it "sends a GET request to list messages" do
      expect(HTTParty).to receive(:get).with(
        "https://api.openai.com/v1/threads/thread_id/messages",
        { headers: described_class.headers }
      )
      described_class.list_messages("thread_id" => "thread_id")
    end
  end

  describe "#body" do
    it "generates the correct request body" do
      body = described_class.body
      expect(body).to eq(
        {
          assistant_id: "assistant_id",
          thread: {
            messages: [
              { role: "user", content: "prompt" }
            ]
          }
        }.to_json
      )
    end
  end

  describe "#headers" do
    it "generates the correct request headers" do
      headers = described_class.headers
      expect(headers).to eq(
        {
          "Authorization" => "Bearer openai_secret",
          "Content-Type" => "application/json",
          "OpenAI-Beta" => "assistants=v2"
        }
      )
    end
  end

  describe "#poll_run" do
    it "polls until the run is completed" do
      allow(HTTParty).to receive(:get).and_return(
        { "status" => "queued" },
        { "status" => "in_progress" },
        completed_response
      )
      response = described_class.poll_run("thread_id" => "thread_id", "id" => "run_id")
      expect(response).to eq(completed_response)
    end

    it "handles failed status" do
      allow(HTTParty).to receive(:get).and_return({ "status" => "failed" })
      response = described_class.poll_run("thread_id" => "thread_id", "id" => "run_id")
      expect(response["status"]).to eq("failed")
    end
  end
end
