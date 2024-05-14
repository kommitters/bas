# frozen_string_literal: true

require "bas/read/default"

RSpec.describe Read::Default do
  before do
    config = {}
    @reader = described_class.new(config)
  end

  describe ".execute" do
    it "provides no implementation for the method" do
      expect(@reader.execute).to be_a Read::Types::Response
    end
  end
end
