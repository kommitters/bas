# frozen_string_literal: true

require "spec_helper"
require "bas/orchestrator/manager"

RSpec.describe Bas::Orchestrator::Manager do
  let(:schedules) do
    [
      { path: "websites_availability/fetch_domain_services_from_notion.rb", interval: 600_000 },
      { path: "websites_availability/notify_domain_availability.rb", interval: 60_000 },
      { path: "websites_availability/garbage_collector.rb", time: ["00:00"] },
      { path: "pto_next_week/fetch_next_week_pto_from_notion.rb", time: ["12:40"], day: ["Monday"] },
      { path: "pto/fetch_pto_from_notion.rb", time: ["13:10"] }
    ]
  end

  let(:manager) { described_class.new(schedules) }

  before do
    allow(manager).to receive(:current_time).and_return("12:40")
    allow(manager).to receive(:current_day).and_return("Monday")
    allow(manager).to receive(:time_in_milliseconds).and_return(10_000)
    allow(manager).to receive(:system).and_return(true)
  end

  describe "#execute_interval" do
    it "executes scripts when interval has elapsed" do
      script = schedules[0]
      manager.instance_variable_set(:@last_executions, { script[:path] => 0 })
      allow(manager).to receive(:time_in_milliseconds).and_return(600_000)

      expect { manager.send(:execute_interval, script) }.to(change do
        manager.instance_variable_get(:@last_executions)[script[:path]]
      end)
    end

    it "does not execute script if interval has not elapsed" do
      script = schedules[0]
      manager.instance_variable_set(:@last_executions, { script[:path] => 0 })
      allow(manager).to receive(:time_in_milliseconds).and_return(10_000)

      expect { manager.send(:execute_interval, script) }.not_to(change do
        manager.instance_variable_get(:@last_executions)[script[:path]]
      end)
    end
  end

  describe "#execute_time" do
    it "executes scripts at exact time" do
      script = schedules[2]
      allow(manager).to receive(:current_time).and_return("00:00")

      expect { manager.send(:execute_time, script) }.to(change do
        manager.instance_variable_get(:@last_executions)[script[:path]]
      end)
    end
  end

  describe "#execute_day" do
    it "executes scripts at specific time and day" do
      script = schedules[3]
      allow(manager).to receive(:current_time).and_return("12:40")
      allow(manager).to receive(:current_day).and_return("Monday")

      expect { manager.send(:execute_day, script) }.to(change do
        manager.instance_variable_get(:@last_executions)[script[:path]]
      end)
    end

    it "does not execute script if time is correct but the day is incorrect" do
      script = schedules[3]
      allow(manager).to receive(:current_time).and_return("12:40")
      allow(manager).to receive(:current_day).and_return("Tuesday")

      expect { manager.send(:execute_day, script) }.not_to(change do
        manager.instance_variable_get(:@last_executions)[script[:path]]
      end)
    end
  end
end
