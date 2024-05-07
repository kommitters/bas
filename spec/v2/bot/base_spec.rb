# frozen_string_literal: true

require "v2/bot/base"

RSpec.describe Bot::Base do
  before do
    config = { read_options: {}, write_options: {}, process_options: {} }

    @bot = described_class.new(config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@bot).to respond_to(:execute).with(0).arguments }

    it { expect(@bot).to respond_to(:read_options) }
    it { expect(@bot).to respond_to(:process_options) }
    it { expect(@bot).to respond_to(:write_options) }
  end

  describe ".execute" do
    it "provides no implementation for the method read" do
      expect { @bot.execute }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end

    it "provides no implementation for the method process" do
      allow_any_instance_of(described_class).to receive(:read).and_return(true)

      expect { @bot.execute }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end

    it "provides invalid process response if process method not returns a hash" do
      allow_any_instance_of(described_class).to receive(:read).and_return(true)
      allow_any_instance_of(described_class).to receive(:process).and_return(true)

      expect { @bot.execute }.to raise_exception(Utils::Exceptions::InvalidProcessResponse)
    end

    it "provides no implementation for the method write" do
      allow_any_instance_of(described_class).to receive(:read).and_return(true)
      allow_any_instance_of(described_class).to receive(:process).and_return({})

      expect { @bot.execute }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end
  end
end
