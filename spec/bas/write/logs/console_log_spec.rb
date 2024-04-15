# frozen_string_literal: true

RSpec.describe Write::Logs::ConsoleLog do
  before do
    @process_response = Process::Types::Response.new("")
    @write = described_class.new()
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }

    it { expect(@write).to respond_to(:config) }
    it { expect(@write).to respond_to(:execute).with(1).arguments }
  end

  describe ".execute" do
    it 'print a console log \'Process Executed\'' do
      expect(@write.execute(@process_response)).to eq(true)
    end
  end
end