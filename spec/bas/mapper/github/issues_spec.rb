# frozen_string_literal: true

RSpec.describe Mapper::Github::Issues do
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
    @mapper = described_class.new
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@mapper).to respond_to(:map).with(1).arguments }
  end

  describe ".map" do
    it "maps the given data into an array of Domain::Issue instances" do
      mapped_data = @mapper.map(@imap_response)

      are_issues = mapped_data.all? { |element| element.is_a?(Domain::Issue) }

      expect(mapped_data).to be_an_instance_of(Array)
      expect(mapped_data.length).to eq(1)
      expect(are_issues).to be_truthy
    end
  end
end
