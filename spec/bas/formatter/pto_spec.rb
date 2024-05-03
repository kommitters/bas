# frozen_string_literal: true

require "bas/formatter/pto"

RSpec.describe Formatter::Pto do
  before do
    day_from_interval = { from: "2024-01-11T19:00:00-05:00", to: "2024-01-11T23:00:00-05:00" }
    day_to_interval = { from: "2024-01-17T12:00:00-05:00", to: "2024-01-17T16:00:00-05:00" }

    @data = [
      Domain::Pto.new("Range PTO", { from: "2024-01-11" }, { from: "2024-01-13" }),
      Domain::Pto.new("Time PTO", { from: "2024-03-13T08:00:00.000-05:00" }, { from: "2024-03-13T12:00:00.000-05:00" }),
      Domain::Pto.new("Time PTO", { from: "2024-03-13T18:00:00.000" }, { from: "2024-03-13T19:00:00.000" }),
      Domain::Pto.new("Day PTO", { from: "2024-01-11" }, { from: "2024-01-11" }),
      Domain::Pto.new("Day PTO", day_from_interval, { from: "2024-01-17" }),
      Domain::Pto.new("Day PTO", { from: "2024-01-11" }, day_to_interval)
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
        template: ":beach: individual_name is on PTO",
        timezone: "-05:00"
      }

      @formatter = described_class.new(options)
    end

    it "format the given data into a specific message" do
      formatted_message = @formatter.format(@data)
      expectation = ":beach: Range PTO is on PTO from 2024-01-11 to 2024-01-13\n" \
                    ":beach: Time PTO is on PTO the day 2024-03-13 from 08:00 am to 12:00 pm\n" \
                    ":beach: Time PTO is on PTO the day 2024-03-13 from 01:00 pm to 02:00 pm\n" \
                    ":beach: Day PTO is on PTO the day 2024-01-11 all day\n" \
                    ":beach: Day PTO is on PTO from 2024-01-11 (07:00 pm - 11:00 pm) to 2024-01-17\n" \
                    ":beach: Day PTO is on PTO from 2024-01-11 to 2024-01-17 (12:00 pm - 04:00 pm)\n"

      expect(formatted_message).to be_a Formatter::Types::Response
      expect(formatted_message.data).to be_an_instance_of(String)
      expect(formatted_message.data).to eq(expectation)
    end

    it "raises an exception when data is not Domain::Pto type" do
      invalid_data = [{ name: "John Doe", start: "2024-01-18", end: "2024-01-18" },
                      { name: "Jane Doe", start: "2024-01-19", end: "2024-01-23" }]

      expect { @formatter.format(invalid_data) }.to raise_exception(Formatter::Exceptions::InvalidData)
    end
  end
end
