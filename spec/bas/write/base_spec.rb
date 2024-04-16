# frozen_string_literal: true

RSpec.describe Write::Base do
  before do
    @process_response = Process::Types::Response.new("")
    @write = described_class.new({})
  end

  describe "Arguments and methods" do
    it { expect(@write).to respond_to(:config) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@write).to respond_to(:execute).with(1).arguments }
  end

  describe ".execute" do
    it "provides no implementation for the method" do
      expect { @write.execute(@process_response) }.to raise_exception(Domain::Exceptions::FunctionNotImplemented)
    end
  end
end
