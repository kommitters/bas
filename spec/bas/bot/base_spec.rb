# frozen_string_literal: true

require "bas/bot/base"
require "bas/read/types/response"

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
    let(:read_response) { Read::Types::Response.new }

    it "provides no implementation for the method read" do
      expect { @bot.execute }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end

    it "provides no implementation for the method process" do
      allow_any_instance_of(described_class).to receive(:read).and_return(read_response)

      expect { @bot.execute }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end

    it "provides invalid process response if process method not returns a hash" do
      allow_any_instance_of(described_class).to receive(:read).and_return(read_response)
      allow_any_instance_of(described_class).to receive(:process).and_return(true)

      expect { @bot.execute }.to raise_exception(Utils::Exceptions::InvalidProcessResponse)
    end

    it "provides no implementation for the method write" do
      allow_any_instance_of(described_class).to receive(:read).and_return(read_response)
      allow_any_instance_of(described_class).to receive(:process).and_return({})

      expect { @bot.execute }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end
  end

  describe ".execute successful" do
    let(:pg_conn) { instance_double(PG::Connection) }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "execute the bot with an old record found" do
      read_response = Read::Types::Response.new(1, {}, "date")

      allow_any_instance_of(described_class).to receive(:read).and_return(read_response)
      allow_any_instance_of(described_class).to receive(:process).and_return({})
      allow_any_instance_of(described_class).to receive(:write).and_return(true)

      @bot.execute

      expect(@bot.read_response).to eql(read_response)
      expect(@bot.process_response).to eql({})
      expect(@bot.write_response).to eql(true)
    end
  end
end
