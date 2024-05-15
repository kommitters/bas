# frozen_string_literal: true

require "bas/read/base"

RSpec.describe Read::Base do
  before do
    config = {}
    @reader = described_class.new(config)
  end

  describe ".execute" do
    it "provides no implementation for the method" do
      expect { @reader.execute }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end
  end
end
