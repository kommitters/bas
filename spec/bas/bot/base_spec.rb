# frozen_string_literal: true

require "bas/bot/base"
require "bas/shared_storage/types/read"

RSpec.describe Bas::Bot::Base do
  before do
    @options = { close_connections_after_process: true }
    @shared_storage_reader = double(:shared_storage_reader, set_in_process: "in-process", set_processed: "processed",
                                                            close_connections: true)
    @shared_storage_writer = double(:shared_storage_writer, close_connections: true)

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
      allow(@shared_storage_reader).to receive(:read).and_return(read_response)

      expect { @bot.execute }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end

    it "provides invalid process response if process method not returns a hash" do
      allow(@shared_storage_reader).to receive(:read).and_return(read_response)
      allow_any_instance_of(described_class).to receive(:process).and_return(true)

      expect { @bot.execute }.to raise_exception(Utils::Exceptions::InvalidProcessResponse)
    end

    it "execute successfully the bot" do
      allow(@shared_storage_reader).to receive(:read).and_return(read_response)
      allow_any_instance_of(described_class).to receive(:process).and_return({})
      allow(@shared_storage_writer).to receive(:write).and_return({})

      @bot.execute

      expect(@bot.read_response).to eql(read_response)
      expect(@bot.process_response).to eql({})
      expect(@bot.write_response).to eql({})
    end

    it "closes the connections when close_connections_after_process is true" do
      allow(@shared_storage_reader).to receive(:read).and_return(read_response)
      allow(@shared_storage_writer).to receive(:write).and_return({})
      allow(@shared_storage_reader).to receive(:close_connections).and_return(true)
      allow(@shared_storage_writer).to receive(:close_connections).and_return(true)
      allow_any_instance_of(described_class).to receive(:process).and_return({ success: "ok" })
      allow(@shared_storage_reader).to receive(:respond_to?).with(:close_connections).and_return(true)
      allow(@shared_storage_writer).to receive(:respond_to?).with(:close_connections).and_return(true)

      bot = described_class.new({ close_connections_after_process: true }, @shared_storage_reader,
                                @shared_storage_writer)
      bot.execute

      expect(@shared_storage_reader).to have_received(:close_connections)
      expect(@shared_storage_writer).to have_received(:close_connections)
    end

    it "does not close the connections when close_connections_after_process is false" do
      allow(@shared_storage_reader).to receive(:read).and_return(read_response)
      allow(@shared_storage_writer).to receive(:write).and_return({})
      allow(@shared_storage_reader).to receive(:close_connections).and_return(true)
      allow(@shared_storage_writer).to receive(:close_connections).and_return(true)
      allow_any_instance_of(described_class).to receive(:process).and_return({ success: "ok" })

      options = { close_connections_after_process: false }
      bot = described_class.new(options, @shared_storage_reader, @shared_storage_writer)

      bot.execute

      expect(@shared_storage_reader).not_to have_received(:close_connections)
      expect(@shared_storage_writer).not_to have_received(:close_connections)
    end
  end

  describe ".unprocessable_response" do
    let(:read_response) { double(:read_response) }

    before do
      allow(@shared_storage_reader).to receive(:read).and_return(read_response)
      allow_any_instance_of(described_class).to receive(:process).and_return({})
      allow(@shared_storage_writer).to receive(:write).and_return({})
    end

    it "return false when the response is processable" do
      allow(read_response).to receive(:data).and_return({ data: "ok" })

      @bot.execute

      expect(@bot.send(:unprocessable_response)).to eql(false)
    end

    it "return true when the response nil" do
      allow(read_response).to receive(:data).and_return(nil)

      @bot.execute

      expect(@bot.send(:unprocessable_response)).to eql(true)
    end

    it "return true when the response is an empty hash" do
      allow(read_response).to receive(:data).and_return({})

      @bot.execute

      expect(@bot.send(:unprocessable_response)).to eql(true)
    end

    it "return true when a value of the hash is nil" do
      allow(read_response).to receive(:data).and_return({ key: nil })

      @bot.execute

      expect(@bot.send(:unprocessable_response)).to eql(true)
    end

    it "return true when a value of the hash is an empty array" do
      allow(read_response).to receive(:data).and_return({ key: [] })

      @bot.execute

      expect(@bot.send(:unprocessable_response)).to eql(true)
    end

    it "return true when a value of the hash is an empty string" do
      allow(read_response).to receive(:data).and_return({ key: "" })

      @bot.execute

      expect(@bot.send(:unprocessable_response)).to eql(true)
    end
  end

  describe ".write" do
    let(:read_response) { double(:read_response) }

    before do
      allow(@shared_storage_reader).to receive(:read).and_return(read_response)
      allow_any_instance_of(described_class).to receive(:process).and_return({})
    end

    it "write the process response when the response is processable" do
      allow(read_response).to receive(:data).and_return({ data: "ok" })
      allow(@shared_storage_writer).to receive(:write).and_return({})

      @bot.execute

      expect(@shared_storage_writer).to have_received(:write).with({})
    end

    it "ignore write if avoid_empty_data is set to true on options" do
      options = { avoid_empty_data: true }
      bot = described_class.new(options, @shared_storage_reader, @shared_storage_writer)

      allow(read_response).to receive(:data).and_return({})
      allow(@shared_storage_writer).to receive(:write).and_return({})

      bot.execute

      expect(@shared_storage_writer).not_to have_received(:write)
    end
  end

  describe ".empty_data?" do
    before do
      allow(@bot).to receive(:process_response)
    end

    it "returns true when process_response is nil" do
      allow(@bot).to receive(:process_response).and_return(nil)
      expect(@bot.send(:empty_data?)).to eql(true)
    end

    it "returns true when process_response is an empty hash" do
      allow(@bot).to receive(:process_response).and_return({})
      expect(@bot.send(:empty_data?)).to eql(true)
    end

    it "returns true when process_response has a key with value nil" do
      allow(@bot).to receive(:process_response).and_return({ key: nil })
      expect(@bot.send(:empty_data?)).to eql(true)
    end

    it "returns true when process_response has a key with value empty array" do
      allow(@bot).to receive(:process_response).and_return({ key: [] })
      expect(@bot.send(:empty_data?)).to eql(true)
    end

    it "returns true when process_response has a key with value empty string" do
      allow(@bot).to receive(:process_response).and_return({ key: "" })
      expect(@bot.send(:empty_data?)).to eql(true)
    end

    it "returns true when process_response has a key with value empty hash" do
      allow(@bot).to receive(:process_response).and_return({ key: {} })
      expect(@bot.send(:empty_data?)).to eql(true)
    end

    it "returns false when process_response has valid values" do
      allow(@bot).to receive(:process_response).and_return({ key: "valid_value" })
      expect(@bot.send(:empty_data?)).to eql(false)
    end
  end
end
