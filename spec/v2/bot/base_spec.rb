# frozen_string_literal: true

require "v2/bot/base"

RSpec.describe Bot::Base do
  before do
    config = { read_options: {}, write_options: {}, process_options: {} }

    @bot = described_class.new(config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@bot).to respond_to(:execute).with(0).arguments }

    it { expect(@bot).to respond_to(:read_options) }
    it { expect(@bot).to respond_to(:process_options) }
    it { expect(@bot).to respond_to(:write_options) }
  end
end
