# frozen_string_literal: true

RSpec.describe Dispatcher::Base do
  before do
    @config = { webhook: "https://example.com/webhook", name: "Example Name" }
    @dispatcher = described_class.new(@config)
  end

  describe "Arguments and methods" do
    it { expect(@dispatcher).to respond_to(:webhook) }
    it { expect(@dispatcher).to respond_to(:name) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@dispatcher).to respond_to(:dispatch).with(1).arguments }
  end

  describe ".dispatch" do
    it "provides no implementation for the method" do
      payload = ""
      expect { @dispatcher.dispatch(payload) }.to raise_exception(Domain::Exceptions::FunctionNotImplemented)
    end
  end
end
