# frozen_string_literal: true

RSpec.describe Formatter::Base do
  before do
    config = {}
    @formatter = described_class.new(config)
  end

  describe ".format" do
    it "provides no implementation for the method" do
      data = []
      expect { @formatter.format(data) }.to raise_exception(Domain::Exceptions::FunctionNotImplemented)
    end
  end
end
