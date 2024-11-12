# frozen_string_literal: true

require "bas/shared_storage/base"

RSpec.describe Bas::SharedStorage::Base do
  let(:read_options) { { tag: "ReadBot" } }
  let(:write_options) { { tag: "WriteBot" } }

  describe "attributes and arguments" do
    before { @shared_storage = described_class.new }

    it { expect(described_class).to respond_to(:new).with(1).arguments }

    it { expect(@shared_storage).to respond_to(:set_in_process) }
    it { expect(@shared_storage).to respond_to(:set_processed) }
  end

  describe ".initialize" do
    it "instantiate a shared storage without read or write config" do
      shared_storage = described_class.new

      expect(shared_storage.read_options).to eql({})
      expect(shared_storage.write_options).to eql({})
    end

    it "instantiate a shared storage with read and write config" do
      shared_storage = described_class.new(read_options:, write_options:)

      expect(shared_storage.read_options).to eql(read_options)
      expect(shared_storage.write_options).to eql(write_options)
    end
  end

  describe ".read" do
    it "throw a function not implemented error" do
      shared_storage = described_class.new

      expect { shared_storage.send(:read) }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end
  end

  describe ".write" do
    it "throw a function not implemented error" do
      shared_storage = described_class.new

      expect { shared_storage.send(:write) }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end
  end
end
