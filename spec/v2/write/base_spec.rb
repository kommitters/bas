# frozen_string_literal: true

require "v2/write/base"

RSpec.describe Write::Base do
  before do
    config = {}
    process_response = {}

    @writer = described_class.new(config, process_response)
  end

  describe ".execute" do
    it "provides no implementation for the method" do
      expect { @writer.execute }.to raise_exception(Utils::Exceptions::FunctionNotImplemented)
    end
  end
end
