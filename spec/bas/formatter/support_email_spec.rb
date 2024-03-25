# frozen_string_literal: true

RSpec.describe Formatter::SupportEmails do
  before do
    @data = [
      Domain::Email.new("error1", "user1@mail.com", "2024-03-13T12:00:00.000-05:00"),
      Domain::Email.new("error2", "user2@mail.com", "2024-03-13T12:00:00.000-05:00")
    ]
  end

  describe "attributes and arguments" do
    before { @formatter = described_class.new }

    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@formatter).to respond_to(:format).with(1).arguments }
  end

  describe ".format with custom template" do
    before do
      options = {
        template: ":warning: The sender has requested support the date"
      }

      @formatter = described_class.new(options)
    end

    it "format the given data into a specific message" do
      formatted_message = @formatter.format(@data)
      expectation = ":warning: The user1@mail.com has requested support the 2024-03-13 05:00:00 PM\n" \
                    ":warning: The user2@mail.com has requested support the 2024-03-13 05:00:00 PM\n"

      expect(formatted_message).to be_an_instance_of(String)
      expect(formatted_message).to eq(expectation)
    end

    it "raises an exception when data is not Domain::Email type" do
      invalid_data = [{ subject: "error", sender: "user1@mail.com", date: "2024-01-18" }]

      expect { @formatter.format(invalid_data) }.to raise_exception(Formatter::Exceptions::InvalidData)
    end
  end
end
