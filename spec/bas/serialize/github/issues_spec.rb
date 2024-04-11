# frozen_string_literal: true

RSpec.describe Serialize::Github::Issues do
  let(:assignees) { [{ login: "username" }] }
  let(:issues) do
    [{
      url: "repo_url",
      title: "title",
      state: "state",
      assignees: assignees,
      description: "description"
    }]
  end

  before do
    @imap_response = Read::Github::Types::Response.new(issues)
    @serialize = described_class.new
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@serialize).to respond_to(:execute).with(1).arguments }
  end

  describe ".execute" do
    it "serialize the given data into an array of Domain::Issue instances" do
      serialized_data = @serialize.execute(@imap_response)

      are_issues = serialized_data.all? { |element| element.is_a?(Domain::Issue) }

      expect(serialized_data).to be_an_instance_of(Array)
      expect(serialized_data.length).to eq(1)
      expect(are_issues).to be_truthy
    end
  end
end
