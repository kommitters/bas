# frozen_string_literal: true

require "bas/process/openai/use_case/humanize_pto"
require "bas/formatter/types/response"

RSpec.describe Process::OpenAI::HumanizePto do
  require "webmock/rspec"

  before do
    @config = {
      secret: "sk-proj-abcdef",
      model: "gpt-4"
    }

    payload = ":beach: John Doe is on PTO from 2024-04-15 to 2024-04-19\n:beach: Jane Doe is on PTO from 2024-04-08 to 2024-04-22\n" # rubocop:disable Layout/LineLength
    @format_response = Formatter::Types::Response.new(payload)

    @process = described_class.new(@config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@process).to respond_to(:execute).with(1).arguments }
    it { expect(@process).to respond_to(:config) }
  end

  describe ".execute" do
    let(:openai_response_body) { { "choices": [] } }
    let(:openai_error_response_body) { { "choices": [] } }
    let(:request_body) do
      "{\"model\":\"gpt-4\",\"n\":1,\"messages\":[{\"role\":\"user\",\"content\":"\
      "\"The following message is too complex for a human to read since it has specific"\
      " dates formatted as YYYY-MM-DD:\\n\\n\\\":beach: John Doe is on PTO from 2024-04-15"\
      " to 2024-04-19\\n:beach: Jane Doe is on PTO from 2024-04-08 to 2024-04-22\\n\\\"\\n\\n"\
      "Create a text that gives the same message in a more human-readable and context-valuable "\
      "fashion for a human.\\nUse the current date (Friday, 2024-04-19) to provide context.\\nTry"\
      " grouping information and using bullet points to make it easier to read the information at "\
      "a quick glance.\\nAdditionally, keep in mind that we work from Monday to Friday - not weekends"\
      ".\\nPlease, just give the PTOs message and avoid the intro message such as \\\"Here is a "\
      "reader-friendly message\\\".\\nAdd emojis for a cool message, but keep it seriously.\\n\\nFor "\
      "example:\\nThe input \\\"Jane Doe is on PTO from 2024-04-08 to 2024-04-26\\\", means that Jane "\
      "will be on PTO starting at 2024-04-08\\nand ending at 2024-04-26, i.e, she will be back the next"\
      " work-day which is 2024-04-29.\\n\"}]}"
    end
    let(:headers) do
      {
        "Authorization" => "Bearer sk-proj-abcdef",
        "Content-Type" => "application/json"
      }
    end

    it "process the openAI response" do
      response_body =
        { "id" => "chatcmpl-9F7YZ9xnfdLv55YRLo05LUocV54Ly",
          "object" => "chat.completion",
          "created" => 1_713_390_995,
          "model" => "gpt-4-0613",
          "choices" => [{ "index" => 0, "message" => { "role" => "assistant", "content" => "- John Doe:\n    - Starting PTO: Monday, April 15th, 2024\n    - Ending PTO: Friday, April 19th, 2024\n    - Total Days: 5 workdays \n\n- Jane Doe:\n    - Starting PTO: Monday, April 8th, 2024\n    - Ending PTO: Monday, April 22nd, 2024\n    - Total Days: 11 workdays (This includes a weekend)" }, "logprobs" => nil, "finish_reason" => "stop" }], "usage" => { "prompt_tokens" => 232, "completion_tokens" => 132, "total_tokens" => 364 }, "system_fingerprint" => nil } # rubocop:disable Layout/LineLength

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          body: request_body,
          headers:
        )
        .to_return_json(status: 200, body: response_body, headers: {})
    end

    it "fails if the openAI response status code is not 200" do
      response_body = {
        "error" => {
          "message" => "Incorrect API key provided: sk-proj-******. You can find your API key at https://platform.openai.com/account/api-keys.",
          "type" => "invalid_request_error",
          "param" => nil,
          "code" => "invalid_api_key"
        }
      }

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          body: request_body,
          headers:
        )
        .to_return_json(status: 401, body: response_body, headers: {})
      expect do
        @process.execute(@format_response)
      end.to raise_exception(StandardError)
    end
  end
end
