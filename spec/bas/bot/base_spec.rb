# frozen_string_literal: true

require "bas/bot/base"
require "bas/shared_storage/types/read"

RSpec.describe Bas::Bot::Base do
  before do
    @options = {}
    @shared_storage_reader = double(:shared_storage_reader, set_in_process: "in-process", set_processed: "processed")
    @shared_storage_writer = double(:shared_storage_writer)

    @bot = described_class.new(@options, @shared_storage_reader, @shared_storage_writer)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(2).arguments }
    it { expect(described_class).to respond_to(:new).with(3).arguments }
    it { expect(@bot).to respond_to(:execute).with(0).arguments }

    it { expect(@bot).to respond_to(:process_options) }
    it { expect(@bot).to respond_to(:shared_storage_reader) }
    it { expect(@bot).to respond_to(:shared_storage_writer) }
    it { expect(@bot).to respond_to(:read_response) }
    it { expect(@bot).to respond_to(:process_response) }
    it { expect(@bot).to respond_to(:write_response) }
  end

  describe ".initialize" do
    it "instantiate a bot with a single shared storage" do
      bot = described_class.new(@options, @shared_storage_reader, @shared_storage_writer)

      expect(bot.process_options).to eql(@options)
      expect(bot.shared_storage_reader).to eql(@shared_storage_reader)
      expect(bot.shared_storage_writer).to eql(@shared_storage_writer)
      expect(bot.shared_storage_reader).not_to eql(@shared_storage_writer)
      expect(bot.shared_storage_writer).not_to eql(@shared_storage_reader)
    end

    it "instantiate a bot with a shared storage for read and other for write" do
      bot = described_class.new(@options, @shared_storage_reader)

      expect(bot.process_options).to eql(@options)
      expect(bot.shared_storage_reader).to eql(@shared_storage_reader)
      expect(bot.shared_storage_writer).to eql(@shared_storage_reader)
    end
  end

  describe ".execute" do
    let(:read_response) { Bas::SharedStorage::Types::Read.new }

    it "provides no implementation for the method process" do
      allow_any_instance_of(described_class).to receive(:read).and_return(read_response)

      expect { @bot.execute }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end

    it "provides invalid process response if process method not returns a hash" do
      allow_any_instance_of(described_class).to receive(:read).and_return(read_response)
      allow_any_instance_of(described_class).to receive(:process).and_return(true)

      expect { @bot.execute }.to raise_exception(Utils::Exceptions::InvalidProcessResponse)
    end

    it "execute successfully the bot" do
      allow_any_instance_of(described_class).to receive(:read).and_return(read_response)
      allow_any_instance_of(described_class).to receive(:process).and_return({})
      allow_any_instance_of(described_class).to receive(:write).and_return({})

      @bot.execute

      expect(@bot.read_response).to eql(read_response)
      expect(@bot.process_response).to eql({})
      expect(@bot.write_response).to eql({})
    end
  end
end
