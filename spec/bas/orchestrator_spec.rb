# frozen_string_literal: true

require "spec_helper"
require "bas/orchestrator"

RSpec.describe Bas::Orchestrator do
  let(:schedules) do
    [
      { path: "websites_availability/fetch_domain_services_from_notion.rb", interval: 600_000 },
      { path: "websites_availability/notify_domain_availability.rb", interval: 60_000 },
      { path: "websites_availability/garbage_collector.rb", time: ["00:00"] },
      { path: "pto_next_week/fetch_next_week_pto_from_notion.rb", time: ["12:40"], day: ["Monday"] },
      { path: "pto/fetch_pto_from_notion.rb", time: ["13:10"] }
    ]
  end

  let(:manager) { instance_double(Bas::Orchestrator::Manager, run: true) }

  before do
    allow(Bas::Orchestrator::Manager).to receive(:new).with(schedules).and_return(manager)
  end

  describe ".start" do
    it "initializes and runs the manager" do
      expect(manager).to receive(:run)
      described_class.start(schedules)
    end
  end
end
