# frozen_string_literal: true

RSpec.describe Dispatcher::Slack::Implementation do
  before do
    @config = {
      webhook: "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX",
      name: "Test Bot"
    }

    @payload = "Some payload, to be sent, including icons :grinning:"

    @dispatcher = described_class.new(@config)
  end

  describe "attributes and arguments" do
    it { expect(@dispatcher).to respond_to(:webhook) }
    it { expect(@dispatcher).to respond_to(:name) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@dispatcher).to respond_to(:dispatch).with(1).arguments }
  end

  describe ".dispatch" do
    it "dispatch a notification message to slack" do
      VCR.use_cassette("/slack/success_dispatch") do
        discords_dispatcher = described_class.new(@config)

        response = discords_dispatcher.dispatch(@payload)

        expect(response).to be_an_instance_of(Dispatcher::Discord::Types::Response)
        expect(response.http_code).to eq(200)
      end
    end

    it "doesn't dispatch a notification message to slack caused by empty payload" do
      VCR.use_cassette("/slack/failed_dispatch_empty_payload") do
        discords_dispatcher = described_class.new(@config)

        response = discords_dispatcher.dispatch("")
        expect(response).to be_an_instance_of(Dispatcher::Discord::Types::Response)
        expect(response.http_code).to eq(400)
      end
    end

    it "raises an exception caused by incorrect webhook provided" do
      VCR.use_cassette("/slack/failed_dispatch_invalid_webhook") do
        config = @config
        config[:webhook] = "https://hooks.slack.com/services/T00000011/B00000011/XXXXXXXXXXXXXXXXXXXXXXWW"

        discords_dispatcher = described_class.new(config)

        expect do
          discords_dispatcher.dispatch(@payload)
        end.to raise_exception(Dispatcher::Slack::Exceptions::InvalidWebookToken)
      end
    end
  end
end
