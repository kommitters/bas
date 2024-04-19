# frozen_string_literal: true

RSpec.describe Serialize::Imap::SupportEmails do
  let(:sender) { [{ "mailbox" => "user", "host" => "gmail.com" }] }
  let(:emails) { [double("email", date: "2024-03-13T12:00:00.000-05:00", subject: "subject", sender:)] }

  before do
    @imap_response = Read::Imap::Types::Response.new(emails)
    @serialize = described_class.new
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@serialize).to respond_to(:execute).with(1).arguments }
  end

  describe ".execute" do
    it "serialize the given data into an array of Domain::Email instances" do
      serialized_data = @serialize.execute(@imap_response)

      are_emails = serialized_data.all? { |element| element.is_a?(Domain::Email) }

      expect(serialized_data).to be_an_instance_of(Array)
      expect(serialized_data.length).to eq(1)
      expect(are_emails).to be_truthy
    end
  end
end
