# frozen_string_literal: true

RSpec.describe Process::Base do
  before do
    @config = { webhook: "https://example.com/webhook", name: "Example Name" }
    @process = described_class.new(@config)
  end

  describe "Arguments and methods" do
    it { expect(@process).to respond_to(:webhook) }
    it { expect(@process).to respond_to(:name) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@process).to respond_to(:execute).with(1).arguments }
  end

  describe ".execute" do
    it "provides no implementation for the method" do
      payload = ""
      expect { @process.execute(payload) }.to raise_exception(Domain::Exceptions::FunctionNotImplemented)
    end
  end
end
