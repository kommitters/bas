# frozen_string_literal: true

require "bas/utils/discord/integration"

RSpec.describe Utils::Discord::Integration do
  before do
    @params = {
      webhook: "webhook",
      name: "discordBotName",
      notification: "notification message"
    }
  end

  describe ".execute" do
    let(:response) { double("http_response") }
    before { allow(HTTParty).to receive(:post).and_return(response) }

    it { expect(described_class.execute(@params)).to_not be_nil }
  end

  describe ".body" do
    it {
      expect(described_class.body(@params)).to eq({
        username: @params[:name],
        content: @params[:notification]
      }.to_json)
    }
  end

  describe ".headers" do
    it { expect(described_class.headers).to eq({ "Content-Type" => "application/json" }) }
  end
end
