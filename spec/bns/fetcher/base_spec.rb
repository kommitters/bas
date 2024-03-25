# frozen_string_literal: true

RSpec.describe Fetcher::Base do
  before do
    config = {}
    @fetcher = described_class.new(config)
  end

  describe "Arguments and methods" do
    it { expect(@fetcher).to respond_to(:config) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@fetcher).to respond_to(:fetch).with(0).arguments }
  end

  describe ".fetch" do
    it "provides no implementation for the method" do
      expect { @fetcher.fetch }.to raise_exception(Domain::Exceptions::FunctionNotImplemented)
    end
  end
end
