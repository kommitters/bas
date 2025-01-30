# frozen_string_literal: true

require "bas/utils/exceptions/invalid_process_response"

RSpec.describe Utils::Exceptions::InvalidProcessResponse do
  describe "#initialize" do
    context "when no custom message is provided" do
      it "initializes with the default message" do
        exception = described_class.new
        expect(exception.message).to eq("The Process response should be a Hash type object")
      end
    end

    context "when a custom message is provided" do
      it "initializes with the custom message" do
        custom_message = "Custom error message"
        exception = described_class.new(custom_message)
        expect(exception.message).to eq(custom_message)
      end
    end
  end

  describe "inheritance" do
    it "inherits from StandardError" do
      expect(described_class).to be < StandardError
    end
  end
end
