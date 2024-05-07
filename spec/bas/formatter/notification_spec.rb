# frozen_string_literal: true

require "bas/formatter/notification"

RSpec.describe Formatter::Notification do
  before do
    @data = [Domain::Notification.new("OpenAI notification")]

    @formatter = described_class.new
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@formatter).to respond_to(:format).with(1).arguments }
  end

  describe ".format" do
    it "format the given data into a specific message" do
      formatted_message = @formatter.format(@data)

      expect(formatted_message).to be_a Formatter::Types::Response
      expect(formatted_message.data).to be_an_instance_of(String)
      expect(formatted_message.data).to eq("OpenAI notification")
    end

    it "raises an exception when the data is not Domain::Notification type" do
      invalid_data = [{ notification: "OpenAI notification" }]

      expect { @formatter.format(invalid_data) }.to raise_exception(Formatter::Exceptions::InvalidData)
    end
  end
end
