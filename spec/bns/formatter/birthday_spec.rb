# frozen_string_literal: true

RSpec.describe Formatter::Birthday do
  before do
    @data = [
      Domain::Birthday.new("Jane Doe", "2024-01-11"),
      Domain::Birthday.new("John Doe", "2024-01-18")
    ]
    @formatter = described_class.new
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@formatter).to respond_to(:format).with(1).arguments }
  end

  describe ".format with a custom template" do
    before do
      template = "individual_name, Wishing you a very happy birthday! Enjoy your special day! :birthday: :gift:"

      @formatter = described_class.new({ template: template })
    end

    it "format the given data into a specific message" do
      formatted_message = @formatter.format(@data)
      expectation = "Jane Doe, Wishing you a very happy birthday! Enjoy your special day! :birthday: :gift:\n" \
                    "John Doe, Wishing you a very happy birthday! Enjoy your special day! :birthday: :gift:\n"

      expect(formatted_message).to be_an_instance_of(String)
      expect(formatted_message).to eq(expectation)
    end

    it "raises an exception when the data is not Domain::Birthday type" do
      invalid_data = [{ name: "John Doe", birth_date: "2024-01-18" },
                      { name: "Jane Doe", birth_date: "2024-01-19" }]

      expect { @formatter.format(invalid_data) }.to raise_exception(Formatter::Exceptions::InvalidData)
    end
  end
end
