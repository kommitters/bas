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
  let(:project_root) { "/app/src/use_cases_execution" }

  before do
    allow(ENV).to receive(:[]).with("BAS_PROJECT_ROOT").and_return(project_root)
    allow(manager).to receive(:current_time).and_return("12:40")
    allow(manager).to receive(:current_day).and_return("Monday")
    allow(manager).to receive(:time_in_milliseconds).and_return(10_000)
    allow(manager).to receive(:system).and_return(true)
  end

  describe "#should_execute?" do
    it "executes scripts based on interval when interval has elapsed" do
      script = schedules[0]
      manager.instance_variable_set(:@last_executions, { script[:path] => 0 })
      allow(manager).to receive(:time_in_milliseconds).and_return(600_000)

      expect(manager.send(:should_execute?, script)).to be true
    end

    it "does not execute script if interval has not elapsed" do
      script = schedules[0]
      manager.instance_variable_set(:@last_executions, { script[:path] => 0 })
      allow(manager).to receive(:time_in_milliseconds).and_return(10_000)

      expect(manager.send(:should_execute?, script)).to be false
    end

    it "executes scripts at exact time" do
      script = schedules[2]
      allow(manager).to receive(:current_time).and_return("00:00")

      expect(manager.send(:should_execute?, script)).to be true
    end

    it "executes scripts at specific time and day" do
      script = schedules[3]
      allow(manager).to receive(:current_time).and_return("12:40")
      allow(manager).to receive(:current_day).and_return("Monday")

      expect(manager.send(:should_execute?, script)).to be true
    end

    it "does not execute script if time is correct but the day is incorrect" do
      script = schedules[3]
      allow(manager).to receive(:current_time).and_return("12:40")
      allow(manager).to receive(:current_day).and_return("Tuesday")

      expect(manager.send(:should_execute?, script)).to be false
    end
  end

  describe "#execute" do
    let(:script) { schedules[0] }
    let(:script_path) { File.join(project_root, script[:path]) }

    before do
      allow(File).to receive(:expand_path).and_call_original
      allow(File).to receive(:expand_path).with(anything, project_root).and_return(script_path)
      allow(manager).to receive(:system).with("ruby #{script_path}").and_return(true)
    end

    it "constructs the correct script path and executes it" do
      expect(manager.send(:execute, script)).to be_truthy
    end
  end
end
