# frozen_string_literal: true

RSpec.describe Read::Base do
  before do
    config = {}
    @read = described_class.new(config)
  end

  describe "Arguments and methods" do
    it { expect(@read).to respond_to(:config) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@read).to respond_to(:execute).with(0).arguments }
  end

  describe ".execute" do
    it "provides no implementation for the method" do
      expect { @read.execute }.to raise_exception(Domain::Exceptions::FunctionNotImplemented)
    end
  end
end
