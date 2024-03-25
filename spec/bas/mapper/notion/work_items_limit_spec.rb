# frozen_string_literal: true

RSpec.describe Mapper::Notion::WorkItemsLimit do
  let(:fields) { %w[id individual_name start_date end_date] }
  let(:values) { [%w[5 2024-02-13 user1 2024-02-13 2024-02-14]] }

  before do
    item1 = { "properties" => { "Responsible domain" => { "select" => { "name" => "kommit.admin" } } } }
    item2 = { "properties" => { "Responsible domain" => { "select" => { "name" => "kommit.ops" } } } }
    item3 = { "properties" => { "Responsible domain" => { "select" => { "name" => "kommit.ops" } } } }

    notion_result = { "results" => [item1, item2, item3] }

    @notion_response = Fetcher::Notion::Types::Response.new(notion_result)
    @mapper = described_class.new
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@mapper).to respond_to(:map).with(1).arguments }
  end

  describe ".map" do
    it "maps the given data into an array of Domain::WorkItmesLimit instances" do
      mapped_data = @mapper.map(@notion_response)

      are_work_items = mapped_data.all? { |element| element.is_a?(Domain::WorkItemsLimit) }

      expect(mapped_data).to be_an_instance_of(Array)
      expect(mapped_data.length).to eq(2)
      expect(are_work_items).to be_truthy
    end
  end
end
