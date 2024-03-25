# frozen_string_literal: true

RSpec.describe Formatter::WorkItemsLimit do
  before do
    @data = [
      Domain::WorkItemsLimit.new("kommit.admin", 1),
      Domain::WorkItemsLimit.new("kommit.marketing", 6)
    ]
  end

  describe "attributes and arguments" do
    before { @formatter = described_class.new }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@formatter).to respond_to(:format).with(1).arguments }
  end

  describe ".format with custom template" do
    before do
      options = {
        template: "The domain work-board wip limit was exceeded",
        limits: { "kommit.marketing": 4 }
      }

      @formatter = described_class.new(options)
    end

    it "format the given data into a specific message" do
      formatted_message = @formatter.format(@data)
      expectation = "The kommit.marketing work-board wip limit was exceeded, 6 of 4\n"

      expect(formatted_message).to be_an_instance_of(String)
      expect(formatted_message).to eq(expectation)
    end

    it "raises an exception when data is not Domain::Pto type" do
      invalid_data = [{ domain: "kommit.marketing", total: 6 }]

      expect { @formatter.format(invalid_data) }.to raise_exception(Formatter::Exceptions::InvalidData)
    end
  end
end
