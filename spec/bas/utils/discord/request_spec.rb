# frozen_string_literal: true

require "bas/utils/discord/request"

RSpec.describe Utils::Discord::Request do
  let(:params) do
    {
      channel_id: "12345",
      secret_token: "discord_bot_token",
      body: "Paragraph 1 --DIVISION-- Paragraph 2 --DIVISION-- Paragraph 3"
    }
  end
  let(:response) { double("http_response", code: 200, body: "success") }

  before do
    allow(HTTParty).to receive(:post).and_return(response)
  end

  describe "#get_discord_images" do
    let(:message) do
      double(
        "message",
        attachments: [double("attachment", url: "https://example.com/image1.jpg")],
        id: "67890",
        channel: double("channel", id: "12345"),
        author: double("author", username: "test_user"),
        timestamp: Time.now
      )
    end

    it "returns the correct media information" do
      result = described_class.get_discord_images(message)

      expect(result).to eq(
        {
          "media" => ["https://example.com/image1.jpg"],
          "message_id" => "67890",
          "channel_id" => "12345",
          "author" => "test_user",
          "timestamp" => message.timestamp.to_s,
          "property" => "images"
        }
      )
    end
  end

  describe "#write_media_text" do
    it "sends a request to Discord API with the correct parameters" do
      combined_paragraphs = "Paragraph 1\n\nParagraph 2"
      described_class.write_media_text(params, combined_paragraphs)

      expect(HTTParty).to have_received(:post).with(
        URI.parse("https://discord.com/api/v10/channels/12345/messages"), # Usar URI.parse
        body: { content: combined_paragraphs }.to_json,
        headers: described_class.headers(params[:secret_token])
      )
    end
  end

  describe "#split_paragraphs" do
    it "splits the paragraphs and sends requests for each pair" do
      expect(HTTParty).to receive(:post).twice.and_return(response)

      described_class.split_paragraphs(params)
    end

    it "does not send a request if paragraphs are empty" do
      empty_params = { channel_id: "12345", secret_token: "discord_bot_token", body: "" }
      expect(HTTParty).not_to receive(:post)

      described_class.split_paragraphs(empty_params)
    end
  end

  describe "#headers" do
    it "returns the correct headers" do
      expect(described_class.headers("discord_bot_token")).to eq(
        {
          "Authorization" => "discord_bot_token",
          "Content-Type" => "application/json"
        }
      )
    end
  end
end
