# frozen_string_literal: true

RSpec.describe Process::OpenAI::HumanizePto do
  require "webmock/rspec"

  before do
    @config = {
      secret: "sk-proj-abcdef",
      model: "gpt-4"
    }

    payload = ":beach: John Doe is on PTO from 2024-04-15 to 2024-04-19\n:beach: Jane Doe is on PTO from 2024-04-08 to 2024-04-22\n"
    @format_response = Formatter::Types::Response.new(payload)

    @process = described_class.new(@config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@process).to respond_to(:execute).with(1).arguments }
    it { expect(@process).to respond_to(:config) }
  end

  describe ".execute" do
    # <HTTParty::Response:0x550 parsed_response={"id"=>"chatcmpl-9F711niQl9ATBgnNChJ2yzObyhDWq", "object"=>"chat.completion", "created"=>1713388915, "model"=>"gpt-4-0613", "choices"=>[{"index"=>0, "message"=>{"role"=>"assistant", "content"=>"- Lorenzo is due for a Paid Time Off (PTO) in about two weeks, from Monday, April 15th to Friday, April 19th, 2024. That's five working days.\n- Luis Humberto Lopez is going on PTO sooner than Lorenzo, starting from the Monday next week, April 8th. He will be back after two full work weeks, on April 22nd, 2024.\n- Then we have Mario Rodriguez going on PTO on the same day as Lorenzo, April 15th. But note that Mario will only be away from 7:00 pm until 11:00 pm. He'll continue to be on PTO on April 16th and will be back on the 17th, 2024."}, "logprobs"=>nil, "finish_reason"=>"stop"}], "usage"=>{"prompt_tokens"=>232, "completion_tokens"=>159, "total_tokens"=>391}, "system_fingerprint"=>nil}, @response=#<Net::HTTPOK 200 OK readbody=true>, @headers={"date"=>["Wed, 17 Apr 2024 21:22:04 GMT"], "content-type"=>["application/json"], "transfer-encoding"=>["chunked"], "connection"=>["close"], "access-control-allow-origin"=>["*"], "cache-control"=>["no-cache, must-revalidate"], "openai-model"=>["gpt-4-0613"], "openai-organization"=>["user-yz68azftlw0yqgpzun2eegpg"], "openai-processing-ms"=>["8774"], "openai-version"=>["2020-10-01"], "strict-transport-security"=>["max-age=15724800; includeSubDomains"], "x-ratelimit-limit-requests"=>["10000"], "x-ratelimit-limit-tokens"=>["10000"], "x-ratelimit-remaining-requests"=>["9999"], "x-ratelimit-remaining-tokens"=>["9772"], "x-ratelimit-reset-requests"=>["8.64s"], "x-ratelimit-reset-tokens"=>["1.368s"], "x-request-id"=>["req_8a36d9e0dffe673e747f0d095d797a61"], "cf-cache-status"=>["DYNAMIC"], "set-cookie"=>["__cf_bm=CQpkcKsZtI286upPuzDm7lxyrW2f0JhAR2DXahX0254-1713388924-1.0.1.1-8sexwfIGaYs3_iuXW4uycHUtS8NorMdyPqLx4Hpe9Mh9D.UuQTMUi0K2gvQRn0OR.3yW_hYPuj.sNG9TUXB5gQ; path=/; expires=Wed, 17-Apr-24 21:52:04 GMT; domain=.api.openai.com; HttpOnly; Secure; SameSite=None", "_cfuvid=KG4.ypK_NKiROJy5Ic4N_9o6jLVYj8HRTcqYOqO1rhU-1713388924092-0.0.1.1-604800000; path=/; domain=.api.openai.com; HttpOnly; Secure; SameSite=None"], "server"=>["cloudflare"], "cf-ray"=>["875f77b01cc2335b-MIA"], "alt-svc"=>["h3=\":443\"; ma=86400"]}>

    let(:openai_response_body) { { "choices": [] } }
    let(:openai_error_response_body) { { "choices": [] } }
    let(:request_body) do
      "{\"model\":\"gpt-4\",\"n\":1,\"messages\":[{\"role\":\"user\",\"content\":\"The following message is too complex for a human to read since it has specific dates formatted as YYYY-MM-DD:\\n\\n\\\":beach: John Doe is on PTO from 2024-04-15 to 2024-04-19\\n:beach: Jane Doe is on PTO from 2024-04-08 to 2024-04-22\\n\\\"\\n\\nCreate a text that gives the same message in a more human-readable and context-valuable fashion for a human.\\nUse the current date (Wednesday, 2024-04-17) to provide context.\\nTry grouping information and using bullet points to make it easier to read the information at a quick glance.\\nAdditionally, keep in mind that we work from Monday to Friday - not weekends.\\nPlease, just give the PTOs message and avoid the intro message such as \\\"Here is a reader-friendly message\\\".\\n\"}]}"
    end
    let(:headers) do
      {
        "Authorization" => "Bearer sk-proj-abcdef",
        "Content-Type" => "application/json"
      }
    end

    it "process the openAI response" do
      response_body =
        { "id" => "chatcmpl-9F7YZ9xnfdLv55YRLo05LUocV54Ly", "object" => "chat.completion", "created" => 1_713_390_995,
          "model" => "gpt-4-0613", "choices" => [{ "index" => 0, "message" => { "role" => "assistant", "content" => "- John Doe:\n    - Starting PTO: Monday, April 15th, 2024\n    - Ending PTO: Friday, April 19th, 2024\n    - Total Days: 5 workdays \n\n- Jane Doe:\n    - Starting PTO: Monday, April 8th, 2024\n    - Ending PTO: Monday, April 22nd, 2024\n    - Total Days: 11 workdays (This includes a weekend)" }, "logprobs" => nil, "finish_reason" => "stop" }], "usage" => { "prompt_tokens" => 232, "completion_tokens" => 132, "total_tokens" => 364 }, "system_fingerprint" => nil }

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          body: request_body,
          headers:
        )
        .to_return_json(status: 200, body: response_body, headers: {})

      response = @process.execute(@format_response)

      expect(response).to be_a Process::Types::Response
      expect(response.data.status_code).to eq(200)
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
