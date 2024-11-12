# frozen_string_literal: true

require "bas/shared_storage/default"
require "bas/shared_storage/types/read"

RSpec.describe Bas::SharedStorage::Default do
  let(:read_options) { { tag: "ReadBot" } }
  let(:read_response) { Bas::SharedStorage::Types::Read.new }

  before { @shared_storage = described_class.new(read_options:) }

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }

    it { expect(@shared_storage).to respond_to(:set_in_process) }
    it { expect(@shared_storage).to respond_to(:set_processed) }
  end

  describe ".read" do
    it "return a Bas::SharedStorage::Types::Read type" do
      expect(@shared_storage.read).to be_a(Bas::SharedStorage::Types::Read)
    end
  end
end
