# frozen_string_literal: true

require "bas/utils/discord/integration"

RSpec.describe Utils::Discord::Integration do
  let(:params) { { webhook: "https://discord.com/api/webhooks/12345", name: "discordBotName", notification: "notification message" } }
  let(:response) { double("http_response", code: 200, body: "success") }

  before { allow(HTTParty).to receive(:post).and_return(response) }

  describe "#execute" do
    context "when the request is successful" do
      it "sends a request to Discord webhook with the correct parameters" do
        described_class.execute(params)

        expect(HTTParty).to have_received(:post).with(
          params[:webhook],
          body: described_class.body(params),
          headers: described_class.headers
        )
      end

      it "returns the response from the API" do
        result = described_class.execute(params)
        expect(result).to eq(response)
      end
    end

    context "when the webhook URL is invalid" do
      let(:params) { { webhook: "invalid_url", name: "discordBotName", notification: "notification message" } }

      it "raises an error" do
        allow(HTTParty).to receive(:post).and_raise(URI::InvalidURIError)
        expect { described_class.execute(params) }.to raise_error(URI::InvalidURIError)
      end
    end

    context "when the request fails" do
      let(:error_response) { double("http_response", code: 500, body: "error") }

      it "returns the error response" do
        allow(HTTParty).to receive(:post).and_return(error_response)
        result = described_class.execute(params)
        expect(result).to eq(error_response)
      end
    end
  end

  describe "#body" do
    it "returns the correct body format" do
      expect(described_class.body(params)).to eq(
        { username: params[:name], content: params[:notification] }.to_json
      )
    end
  end

  describe "#headers" do
    it "returns the correct headers" do
      expect(described_class.headers).to eq({ "Content-Type" => "application/json" })
    end
  end
end
