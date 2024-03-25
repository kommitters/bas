# frozen_string_literal: true

RSpec.describe Mapper::Postgres::PtoToday do
  let(:fields) { %w[id individual_name start_date end_date] }
  let(:values) { [%w[5 2024-02-13 user1 2024-02-13 2024-02-14]] }

  before do
    pg_result = double

    allow(pg_result).to receive(:res_status).and_return("PGRES_TUPLES_OK")
    allow(pg_result).to receive(:fields).and_return(fields)
    allow(pg_result).to receive(:values).and_return(values)

    @pg_response = Fetcher::Postgres::Types::Response.new(pg_result)
    @mapper = described_class.new
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@mapper).to respond_to(:map).with(1).arguments }
  end

  describe ".map" do
    it "maps the given data into an array of Domain::Pto instances" do
      mapped_data = @mapper.map(@pg_response)

      are_ptos = mapped_data.all? { |element| element.is_a?(Domain::Pto) }

      expect(mapped_data).to be_an_instance_of(Array)
      expect(mapped_data.length).to eq(1)
      expect(are_ptos).to be_truthy
    end
  end
end
