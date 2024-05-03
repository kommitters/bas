# frozen_string_literal: true

require "bas/serialize/notion/work_items_limit"
require "bas/read/notion/types/response"
require "bas/read/notion/use_case/work_items_limit"

RSpec.describe Serialize::Notion::WorkItemsLimit do
  let(:fields) { %w[id individual_name start_date end_date] }
  let(:values) { [%w[5 2024-02-13 user1 2024-02-13 2024-02-14]] }

  before do
    item1 = { "properties" => { "Responsible domain" => { "select" => { "name" => "kommit.admin" } } } }
    item2 = { "properties" => { "Responsible domain" => { "select" => { "name" => "kommit.ops" } } } }
    item3 = { "properties" => { "Responsible domain" => { "select" => { "name" => "kommit.ops" } } } }

    notion_result = { "results" => [item1, item2, item3] }

    @notion_response = Read::Notion::Types::Response.new(notion_result)
    @serialize = described_class.new
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@serialize).to respond_to(:execute).with(1).arguments }
  end

  describe ".execute" do
    it "serialize the given data into an array of Domain::WorkItmesLimit instances" do
      serialized_data = @serialize.execute(@notion_response)

      are_work_items = serialized_data.all? { |element| element.is_a?(Domain::WorkItemsLimit) }

      expect(serialized_data).to be_an_instance_of(Array)
      expect(serialized_data.length).to eq(2)
      expect(are_work_items).to be_truthy
    end
  end
end
