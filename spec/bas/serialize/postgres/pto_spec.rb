# frozen_string_literal: true

RSpec.describe Serialize::Postgres::PtoToday do
  let(:fields) { %w[id individual_name start_date end_date] }
  let(:values) { [%w[5 2024-02-13 user1 2024-02-13 2024-02-14]] }

  before do
    pg_result = double

    allow(pg_result).to receive(:res_status).and_return("PGRES_TUPLES_OK")
    allow(pg_result).to receive(:fields).and_return(fields)
    allow(pg_result).to receive(:values).and_return(values)

    @pg_response = Read::Postgres::Types::Response.new(pg_result)
    @serialize = described_class.new
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@serialize).to respond_to(:execute).with(1).arguments }
  end

  describe ".execute" do
    it "serialize the given data into an array of Domain::Pto instances" do
      serialized_data = @serialize.execute(@pg_response)

      are_ptos = serialized_data.all? { |element| element.is_a?(Domain::Pto) }

      expect(serialized_data).to be_an_instance_of(Array)
      expect(serialized_data.length).to eq(1)
      expect(are_ptos).to be_truthy
    end
  end
end
