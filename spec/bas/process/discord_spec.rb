# frozen_string_literal: true

RSpec.describe Process::Discord::Implementation do
  before do
    @config = {
      webhook: "https://discord.com/api/webhooks/1196541734138691615/lFFCvFdMVEvfKWtFID2TSBjNjjBvEwqRbG2czOz3X_HfHfIgmXh6SDlFRXaXLOignsOj",
      name: "Test Birthday Bot"
    }

    @payload = "John Doe, Wishing you a very happy birthday! Enjoy your special day! :birthday: :gift:"

    @process = described_class.new(@config)
  end

  describe "attributes and arguments" do
    it { expect(@process).to respond_to(:webhook) }
    it { expect(@process).to respond_to(:name) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@process).to respond_to(:execute).with(1).arguments }
  end

  describe ".execute" do
    it "send a notification message to discord" do
      VCR.use_cassette("/discord/success_process") do
        discords_process = described_class.new(@config)

        response = discords_process.execute(@payload)

        expect(response.http_code).to eq(204)
      end
    end

    it "doesn't send a notification message to discord" do
      VCR.use_cassette("/discord/success_process_empty_name") do
        discords_process = described_class.new(@config)

        response = discords_process.execute(@payload)
        expect(response.http_code).to eq(204)
      end
    end

    it "raises an exception caused by incorrect webhook provided" do
      VCR.use_cassette("/discord/failed_process_invalid_webhook") do
        config = @config
        config[:webhook] = "https://discord.com/api/webhooks/1196541734138691615/lFFCvFdMVEvfKWtFID2TSBjNjjBvEwqRbG2czOz3X_JfHfIgmXh6SDlFRXaXLOignsIP"

        discords_process = described_class.new(config)

        expect do
          discords_process.execute(@payload)
        end.to raise_exception(Process::Discord::Exceptions::InvalidWebookToken)
      end
    end
  end
end
