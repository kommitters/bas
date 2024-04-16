# frozen_string_literal: true

RSpec.describe Process::Slack::Implementation do
  before do
    @config = {
      webhook: "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX",
      name: "Test Bot"
    }

    payload = "Some payload, to be sent, including icons :grinning:"
    @format_response = Formatter::Types::Response.new(payload)

    @process = described_class.new(@config)
  end

  describe "attributes and arguments" do
    it { expect(@process).to respond_to(:webhook) }
    it { expect(@process).to respond_to(:name) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@process).to respond_to(:execute).with(1).arguments }
  end

  describe ".execute" do
    it "send a notification message to slack" do
      VCR.use_cassette("/slack/success_process") do
        discords_process = described_class.new(@config)

        response = discords_process.execute(@format_response)

        expect(response).to be_a Process::Types::Response
        expect(response.data).to be_an_instance_of(Process::Discord::Types::Response)
        expect(response.data.http_code).to eq(200)
      end
    end

    it "doesn't send a notification message to slack caused by empty payload" do
      VCR.use_cassette("/slack/failed_process_empty_payload") do
        discords_process = described_class.new(@config)

        format_response = Formatter::Types::Response.new("")

        response = discords_process.execute(format_response)

        expect(response).to be_a Process::Types::Response
        expect(response.data).to be_an_instance_of(Process::Discord::Types::Response)
        expect(response.data.http_code).to eq(400)
      end
    end

    it "raises an exception caused by incorrect webhook provided" do
      VCR.use_cassette("/slack/failed_process_invalid_webhook") do
        config = @config
        config[:webhook] = "https://hooks.slack.com/services/T00000011/B00000011/XXXXXXXXXXXXXXXXXXXXXXWW"

        discords_process = described_class.new(config)

        expect do
          discords_process.execute(@format_response)
        end.to raise_exception(Process::Slack::Exceptions::InvalidWebookToken)
      end
    end
  end
end
