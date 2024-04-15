# frozen_string_literal: true

RSpec.describe Process::Base do
  before do
    @config = { webhook: "https://example.com/webhook", name: "Example Name" }

    @format_response = Formatter::Types::Response.new("")
    @process = described_class.new(@config)
  end

  describe "Arguments and methods" do
    it { expect(@process).to respond_to(:config) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@process).to respond_to(:execute).with(1).arguments }
  end

  describe ".execute" do
    it "provides no implementation for the method" do
      expect(@process.execute(@format_response)).to be_a Process::Types::Response
      # expect { @process.execute(payload) }.to raise_exception(Domain::Exceptions::FunctionNotImplemented)
    end
  end
end
