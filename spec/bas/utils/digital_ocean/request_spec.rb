# frozen_string_literal: true

require "bas/utils/digital_ocean/request"

RSpec.describe Utils::DigitalOcean::Request do
  let(:params) do
    {
      endpoint: "droplets",
      secret: "do_secret",
      method: :get,
      body: nil
    }
  end
  let(:response) { double("http_response", body: { "droplets" => [] }.to_json) }
  let(:url) { "#{Utils::DigitalOcean::Request::DIGITAL_OCEAN_BASE_URL}/#{params[:endpoint]}" }
  let(:headers) do
    {
      "Authorization" => "Bearer #{params[:secret]}",
      "Content-Type" => "application/json"
    }
  end

  before do
    allow(HTTParty).to receive(:get).and_return(response)
    allow(HTTParty).to receive(:post).and_return(response)
  end

  describe "#execute" do
    context "when making a GET request" do
      it "sends a request to the correct URL with the correct headers" do
        described_class.execute(params)

        expect(HTTParty).to have_received(:get).with(url, headers: headers, body: nil)
      end

      it "returns the response from the API" do
        result = described_class.execute(params)

        expect(result).to eq(response)
      end
    end

    context "when making a POST request" do
      let(:params) do
        {
          endpoint: "droplets",
          secret: "do_secret",
          method: :post,
          body: { name: "example" }
        }
      end

      it "sends a request to the correct URL with the correct headers and body" do
        described_class.execute(params)

        expect(HTTParty).to have_received(:post).with(url, headers: headers, body: params[:body].to_json)
      end

      it "returns the response from the API" do
        result = described_class.execute(params)

        expect(result).to eq(response)
      end
    end

    context "when the secret is missing" do
      let(:params) do
        {
          endpoint: "droplets",
          secret: nil,
          method: :get
        }
      end

      it "raises an error" do
        expect { described_class.execute(params) }.to raise_error(ArgumentError, "Secret is required")
      end
    end

    context "when the endpoint is missing" do
      let(:params) do
        {
          endpoint: nil,
          secret: "do_secret",
          method: :get
        }
      end

      it "raises an error" do
        expect { described_class.execute(params) }.to raise_error(ArgumentError, "Endpoint is required")
      end
    end
  end
end
