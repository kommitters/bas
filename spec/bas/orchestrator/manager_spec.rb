# frozen_string_literal: true

require "spec_helper"
require "bas/orchestrator/manager"
require "timecop"

RSpec.describe Bas::Orchestrator::Manager do
  let(:schedules) do
    [
      { path: "websites_availability/fetch_domain_services_from_notion.rb", interval: 600_000 },
      { path: "websites_availability/notify_domain_availability.rb", interval: 60_000 },
      { path: "websites_availability/garbage_collector.rb", time: ["00:00"] },
      { path: "pto_next_week/fetch_next_week_pto_from_notion.rb", time: ["12:40"], day: ["Monday"] },
      { path: "pto/fetch_pto_from_notion.rb", time: ["13:10"] },
      { path: "digital_ocean_bill_alert/fetch_billing_from_digital_ocean.rb",
        custom_rule: { type: "last_day_of_week_in_month", day_of_week: "Friday", time: ["15:00"] } },
      { path: "pto/fetch_next_week_pto_from_notion.rb", custom_rule: { type: "last_day_of_month", time: ["23:59"] } },
      { path: "networks_sync/fetch_networks_emailless_from_notion.rb",
        custom_rule: { type: "last_day_of_week", day_of_week: "Tuesday", time: ["10:00"] } },
      { path: "digital_ocean_bill_alert/fetch_billing_from_digital_ocean.rb",
        custom_rule: { type: "last_day_of_year", time: ["23:00"] } }
    ]
  end

  let(:manager) { described_class.new(schedules) }

  before do
    allow(manager).to receive(:current_time).and_return("12:40")
    allow(manager).to receive(:current_day).and_return("Monday")
    allow(manager).to receive(:time_in_milliseconds).and_return(10_000)
    allow(manager).to receive(:system).and_return(true)
  end

  after do
    Timecop.return
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

  describe "#execute_custom_rule" do
    let(:last_wday_month_script) do
      schedules.find do |s|
        s[:custom_rule] && s[:custom_rule][:type] == "last_day_of_week_in_month"
      end
    end
    let(:last_day_of_month_script) do
      schedules.find do |s|
        s[:custom_rule] && s[:custom_rule][:type] == "last_day_of_month"
      end
    end
    let(:last_day_of_week_script) do
      schedules.find do |s|
        s[:custom_rule] && s[:custom_rule][:type] == "last_day_of_week"
      end
    end
    let(:last_day_of_year_script) do
      schedules.find do |s|
        s[:custom_rule] && s[:custom_rule][:type] == "last_day_of_year"
      end
    end

    before do
      allow(manager).to receive(:execute).and_return(true)
    end

    context "for 'last_day_of_week_in_month' rule type" do
      it "executes script if all conditions are met (time from moment, date logic stubbed true)" do
        current_moment = Time.local(2023, 1, 1, 15, 0, 0)

        allow(manager).to receive(:today_is_last_day_of_week_in_month?)
          .with(current_moment, last_wday_month_script.dig(:custom_rule, :day_of_week))
          .and_return(true)

        expect(manager).to receive(:execute).with(last_wday_month_script)
        expect do
          manager.send(:execute_custom_rule, last_wday_month_script, current_moment)
        end.to change { manager.instance_variable_get(:@last_executions)[last_wday_month_script[:path]] }.to("15:00")
      end
      it "does not execute script if the time does not match" do
        current_moment_wrong_time = Time.local(2023, 1, 1, 14, 59, 0)

        allow(manager).to receive(:today_is_last_day_of_week_in_month?)
          .with(current_moment_wrong_time, last_wday_month_script.dig(:custom_rule, :day_of_week))
          .and_return(true) # We still mock the date logic as true for this test

        expect(manager).not_to receive(:execute).with(last_wday_month_script)
        expect do
          manager.send(:execute_custom_rule, last_wday_month_script, current_moment_wrong_time)
        end.not_to(change { manager.instance_variable_get(:@last_executions)[last_wday_month_script[:path]] })
      end

      it "does not execute script if the date logic returns false" do
        current_moment = Time.local(2023, 1, 1, 15, 0, 0)

        allow(manager).to receive(:today_is_last_day_of_week_in_month?)
          .with(current_moment, last_wday_month_script.dig(:custom_rule, :day_of_week))
          .and_return(false)

        expect(manager).not_to receive(:execute).with(last_wday_month_script)
        expect do
          manager.send(:execute_custom_rule, last_wday_month_script, current_moment)
        end.not_to(change { manager.instance_variable_get(:@last_executions)[last_wday_month_script[:path]] })
      end
    end

    context "for 'last_day_of_month' rule type" do
      it "executes script if it's the last day of the month and the time matches" do
        last_day_moment = Time.local(2025, 5, 31, 23, 59, 0) # Last day of May 2025, 23:59
        allow(manager).to receive(:current_moment).and_return(last_day_moment)

        expect(manager).to receive(:execute).with(last_day_of_month_script)
        expect do
          manager.send(:execute_custom_rule, last_day_of_month_script, last_day_moment)
        end.to change { manager.instance_variable_get(:@last_executions)[last_day_of_month_script[:path]] }.to("23:59")
      end

      it "does not execute if it's not the last day of the month" do
        not_last_day_moment = Time.local(2025, 5, 30, 23, 59, 0)
        allow(manager).to receive(:current_moment).and_return(not_last_day_moment)

        expect(manager).not_to receive(:execute).with(last_day_of_month_script)
        expect do
          manager.send(:execute_custom_rule, last_day_of_month_script, not_last_day_moment)
        end.not_to(change { manager.instance_variable_get(:@last_executions)[last_day_of_month_script[:path]] })
      end

      it "does not execute if the time does not match" do
        last_day_wrong_time = Time.local(2025, 5, 31, 23, 58, 0)
        allow(manager).to receive(:current_moment).and_return(last_day_wrong_time)

        expect(manager).not_to receive(:execute).with(last_day_of_month_script)
        expect do
          manager.send(:execute_custom_rule, last_day_of_month_script, last_day_wrong_time)
        end.not_to(change { manager.instance_variable_get(:@last_executions)[last_day_of_month_script[:path]] })
      end
    end

    context "for 'last_day_of_week' rule type" do
      it "executes script if it's the last specified day of the week and the time matches" do
        # Tuesday, May 27, 2025 is the last Tuesday of May 2025
        last_tuesday_moment = Time.local(2025, 5, 27, 10, 0, 0)
        allow(manager).to receive(:current_moment).and_return(last_tuesday_moment)

        expect(manager).to receive(:execute).with(last_day_of_week_script)
        expect do
          manager.send(:execute_custom_rule, last_day_of_week_script, last_tuesday_moment)
        end.to change { manager.instance_variable_get(:@last_executions)[last_day_of_week_script[:path]] }.to("10:00")
      end

      it "does not execute if it's not the specified last day of the week" do
        # Tuesday, May 20, 2025 is not the last Tuesday of May 2025
        not_last_tuesday_moment = Time.local(2025, 5, 20, 10, 0, 0)
        allow(manager).to receive(:current_moment).and_return(not_last_tuesday_moment)

        expect(manager).not_to receive(:execute).with(last_day_of_week_script)
        expect do
          manager.send(:execute_custom_rule, last_day_of_week_script, not_last_tuesday_moment)
        end.not_to(change { manager.instance_variable_get(:@last_executions)[last_day_of_week_script[:path]] })
      end

      it "does not execute if the time does not match" do
        # Last Tuesday, wrong time
        last_tuesday_wrong_time = Time.local(2025, 5, 27, 9, 59, 0)
        allow(manager).to receive(:current_moment).and_return(last_tuesday_wrong_time)

        expect(manager).not_to receive(:execute).with(last_day_of_week_script)
        expect do
          manager.send(:execute_custom_rule, last_day_of_week_script, last_tuesday_wrong_time)
        end.not_to(change { manager.instance_variable_get(:@last_executions)[last_day_of_week_script[:path]] })
      end
    end

    context "for 'last_day_of_year' rule type" do
      it "executes script if it's the last day of the year and the time matches" do
        last_day_year_moment = Time.local(2025, 12, 31, 23, 0, 0)
        allow(manager).to receive(:current_moment).and_return(last_day_year_moment)

        expect(manager).to receive(:execute).with(last_day_of_year_script)
        expect do
          manager.send(:execute_custom_rule, last_day_of_year_script, last_day_year_moment)
        end.to change { manager.instance_variable_get(:@last_executions)[last_day_of_year_script[:path]] }.to("23:00")
      end

      it "does not execute if it's not the last day of the year" do
        not_last_day_year_moment = Time.local(2025, 12, 30, 23, 0, 0)
        allow(manager).to receive(:current_moment).and_return(not_last_day_year_moment)

        expect(manager).not_to receive(:execute).with(last_day_of_year_script)
        expect do
          manager.send(:execute_custom_rule, last_day_of_year_script, not_last_day_year_moment)
        end.not_to(change { manager.instance_variable_get(:@last_executions)[last_day_of_year_script[:path]] })
      end

      it "does not execute if the time does not match" do
        last_day_year_wrong_time = Time.local(2025, 12, 31, 22, 59, 0)
        allow(manager).to receive(:current_moment).and_return(last_day_year_wrong_time)

        expect(manager).not_to receive(:execute).with(last_day_of_year_script)
        expect do
          manager.send(:execute_custom_rule, last_day_of_year_script, last_day_year_wrong_time)
        end.not_to(change { manager.instance_variable_get(:@last_executions)[last_day_of_year_script[:path]] })
      end
    end

    context "for an unknown custom rule type" do
      it "puts an error message and does not execute" do
        unknown_rule_script = { path: "unknown_script.rb", custom_rule: { type: "some_future_rule" } }
        current_moment = Time.now

        expect(manager).not_to receive(:execute)

        expect do
          manager.send(:execute_custom_rule, unknown_rule_script, current_moment)
        end.to output(/Unknown custom rule type: some_future_rule for script 'unknown_script.rb'/).to_stdout_from_any_process # rubocop:disable Layout/LineLength
      end
    end
  end

  describe "#today_is_last_day_of_week_in_month?(time_obj, target_day_name)" do
    def check_is_last_day_of_week(time_obj, target_day_name)
      manager.send(:today_is_last_day_of_week_in_month?, time_obj, target_day_name)
    end

    context "when target_day_name is 'Friday'" do
      let(:target_day_name) { "Friday" }

      it "returns true for the last Friday of May 2024 (May 31, 2024)" do
        a_moment_on_last_friday = Time.local(2024, 5, 31, 10, 0, 0)
        expect(check_is_last_day_of_week(a_moment_on_last_friday, target_day_name)).to be true
      end

      it "returns false for a Friday that is not the last in the month (May 24, 2024)" do
        a_moment_on_a_friday = Time.local(2024, 5, 24, 10, 0, 0)
        expect(check_is_last_day_of_week(a_moment_on_a_friday, target_day_name)).to be false
      end

      it "returns false for a day that is not the target day (e.g., last Thursday of May 2024)" do
        a_moment_on_a_thursday = Time.local(2024, 5, 30, 10, 0, 0)
        expect(check_is_last_day_of_week(a_moment_on_a_thursday, target_day_name)).to be false
      end
    end

    it "handles target day names case-insensitively" do
      a_moment_on_last_friday = Time.local(2024, 5, 31, 10, 0, 0) # Last Friday of May 2024
      expect(check_is_last_day_of_week(a_moment_on_last_friday, "friday")).to be true
      expect(check_is_last_day_of_week(a_moment_on_last_friday, "FRIDAY")).to be true
      expect(check_is_last_day_of_week(a_moment_on_last_friday, "FriDay")).to be true
    end

    it "returns false if the target_day_name is not a valid day name" do
      a_moment_in_time = Time.local(2024, 5, 31, 10, 0, 0)
      expect(check_is_last_day_of_week(a_moment_in_time, "InvalidDay")).to be false
    end

    it "returns false if the date passed is itself not the target_wday" do
      a_thursday_moment = Time.local(2024, 5, 30, 10, 0, 0)
      expect(check_is_last_day_of_week(a_thursday_moment, "Friday")).to be false
    end
  end
end
