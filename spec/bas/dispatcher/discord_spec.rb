# frozen_string_literal: true

RSpec.describe Dispatcher::Discord::Implementation do
  before do
    @config = {
      webhook: "https://discord.com/api/webhooks/1196541734138691615/lFFCvFdMVEvfKWtFID2TSBjNjjBvEwqRbG2czOz3X_HfHfIgmXh6SDlFRXaXLOignsOj",
      name: "Test Birthday Bot"
    }

    @payload = "John Doe, Wishing you a very happy birthday! Enjoy your special day! :birthday: :gift:"

    @dispatcher = described_class.new(@config)
  end

  describe "attributes and arguments" do
    it { expect(@dispatcher).to respond_to(:webhook) }
    it { expect(@dispatcher).to respond_to(:name) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@dispatcher).to respond_to(:dispatch).with(1).arguments }
  end

  describe ".dispatch" do
    it "dispatch a notification message to discord" do
      VCR.use_cassette("/discord/success_dispatch") do
        discords_dispatcher = described_class.new(@config)

        response = discords_dispatcher.dispatch(@payload)

        expect(response.http_code).to eq(204)
      end
    end

    it "doesn't dispatch a notification message to discord" do
      VCR.use_cassette("/discord/success_dispatch_empty_name") do
        discords_dispatcher = described_class.new(@config)

        response = discords_dispatcher.dispatch(@payload)
        expect(response.http_code).to eq(204)
      end
    end

    it "raises an exception caused by incorrect webhook provided" do
      VCR.use_cassette("/discord/failed_dispatch_invalid_webhook") do
        config = @config
        config[:webhook] = "https://discord.com/api/webhooks/1196541734138691615/lFFCvFdMVEvfKWtFID2TSBjNjjBvEwqRbG2czOz3X_JfHfIgmXh6SDlFRXaXLOignsIP"

        discords_dispatcher = described_class.new(config)

        expect do
          discords_dispatcher.dispatch(@payload)
        end.to raise_exception(Dispatcher::Discord::Exceptions::InvalidWebookToken)
      end
    end
  end
end
