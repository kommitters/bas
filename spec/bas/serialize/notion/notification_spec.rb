# frozen_string_literal: true

RSpec.describe Serialize::Notion::Notification do
  before do
    notification = { "properties" => { "Notification" => { "rich_text" => [{ "plain_text" => "OpenAI notification" }] } } }

    notion_result = { "results" => [notification] }

    @notion_response = Read::Notion::Types::Response.new(notion_result)
    @serialize = described_class.new
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@serialize).to respond_to(:execute).with(1).arguments }
  end

  describe ".execute" do
    it "serialize the given data into an array of Domain::Notification instances" do
      serialized_data = @serialize.execute(@notion_response)

      are_notifications = serialized_data.all? { |element| element.is_a?(Domain::Notification) }

      expect(serialized_data).to be_an_instance_of(Array)
      expect(serialized_data.length).to eq(1)
      expect(are_notifications).to be_truthy
    end
  end
end
