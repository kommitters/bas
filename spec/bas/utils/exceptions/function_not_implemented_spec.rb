# frozen_string_literal: true

require "bas/utils/exceptions/function_not_implemented"

RSpec.describe Utils::Exceptions::FunctionNotImplemented do
  it "raises a FunctionNotImplemented error" do
    expect { raise described_class, "Test error" }.to raise_error(described_class, "Test error")
  end
end
