# frozen_string_literal: true

require "v2/utils/openai/run_assistant"

RSpec.describe Utils::OpenAI::RunAssitant do
  let(:run) { double("run", parsed_response: { "id" => "run_id", "thread_id" => "thread_id" }) }

  before do
    @params = {
      assistant_id: "assistant_id",
      secret: "openai_secret",
      prompt: "prompt"
    }

    @body = {
      assistant_id: @params[:assistant_id],
      thread: {
        messages: [
          role: "user",
          content: @params[:prompt]
        ]
      }
    }.to_json

    @headers = {
      "Authorization" => "Bearer #{@params[:secret]}",
      "Content-Type" => "application/json",
      "OpenAI-Beta" => "assistants=v2"
    }

    allow(HTTParty).to receive(:post).and_return(run)
  end

  describe ".execute" do
    it "should fail if the thread and run creation fails" do
      allow(run).to receive(:code).and_return(404)

      url = "#{described_class::OPENAI_BASE_URL}/v1/threads/runs"

      expect(HTTParty).to receive(:post).with(url, { body: @body, headers: @headers })

      response = described_class.execute(@params)

      expect(response.code).to eq(404)
    end

    it "should fail if the poll run fails" do
      allow(run).to receive(:code).and_return(200)
      allow(HTTParty).to receive(:get).and_return({ "status" => "in_progress" }, { "status" => "failed" })

      run_id = run.parsed_response["id"]
      thread_id = run.parsed_response["thread_id"]

      url = "#{described_class::OPENAI_BASE_URL}/v1/threads/#{thread_id}/runs/#{run_id}"

      expect(HTTParty).to receive(:get).with(url, { headers: @headers })

      response = described_class.execute(@params)

      expect(response["status"]).to eq("failed")
    end

    it "should call the list_message endpoint" do
      allow(run).to receive(:code).and_return(200)
      allow(HTTParty).to receive(:get).and_return({ "status" => "completed", "thread_id" => "thread_id" })

      run_id = run.parsed_response["id"]
      thread_id = run.parsed_response["thread_id"]

      url_pol = "#{described_class::OPENAI_BASE_URL}/v1/threads/#{thread_id}/runs/#{run_id}"
      url_list = "#{described_class::OPENAI_BASE_URL}/v1/threads/#{thread_id}/messages"

      expect(HTTParty).to receive(:get).with(url_pol, { headers: @headers })
      expect(HTTParty).to receive(:get).with(url_list, { headers: @headers })

      described_class.execute(@params)
    end
  end
end
