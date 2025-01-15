# frozen_string_literal: true

require "spec_helper"
require "sidekiq/testing"
require "logger"

RSpec.describe Kiqchestra::Workflow do
  let(:workflow_id) { "test_workflow" }
  let(:dependencies) do
    {
      job_a: [],
      job_b: [:job_a],
      job_c: [:job_a],
      job_d: [:job_b, :job_c],
    }
  end
  let(:logger) { instance_double(Logger, info: nil) }
  let(:workflow) { described_class.new(workflow_id, dependencies, logger: logger) }

  before do
    allow(Rails.cache).to receive(:write)
    allow(Rails.cache).to receive(:read).and_return(nil)
    allow(Object).to receive(:const_get).and_call_original
    allow(Object).to receive(:const_get).with("JobAWorker").and_return(FakeWorker)
    allow(Object).to receive(:const_get).with("JobBWorker").and_return(FakeWorker)
    allow(Object).to receive(:const_get).with("JobCWorker").and_return(FakeWorker)
    allow(Object).to receive(:const_get).with("JobDWorker").and_return(FakeWorker)
  end

  class FakeWorker
    include Sidekiq::Worker

    def self.perform_async(*_args)
      true
    end
  end

  describe "#initialize" do
    it "sets up the workflow with valid dependencies and a logger" do
      expect { workflow }.not_to raise_error
    end

    it "raises an error if dependencies are not a hash" do
      expect { described_class.new(workflow_id, [], logger: logger) }
        .to raise_error(ArgumentError, "Dependencies must be a hash")
    end

    it "raises an error if a dependency value is not an array" do
      invalid_dependencies = { job_a: nil }
      expect { described_class.new(workflow_id, invalid_dependencies, logger: logger) }
        .to raise_error(ArgumentError, "Dependencies for job_a must be an array")
    end
  end

  describe "#execute" do
    it "starts jobs with no dependencies" do
      expect(workflow).to receive(:enqueue_job).with(:job_a).once
      workflow.execute
    end
  end

  describe "#job_completed" do
    before do
      allow(Rails.cache).to receive(:read).with(anything).and_return("{}")
      allow(Rails.cache).to receive(:write)
    end

    it "marks the job as completed and triggers dependent jobs" do
      workflow.execute
      expect(workflow).to receive(:enqueue_job).with(:job_b)
      expect(workflow).to receive(:enqueue_job).with(:job_c)
      workflow.job_completed(:job_a)
    end

    it "completes the workflow when all jobs are done" do
      allow(workflow).to receive(:read_progress).and_return(
        {
          job_a: "completed",
          job_b: "completed",
          job_c: "completed",
          job_d: "completed",
        }
      )
      expect(logger).to receive(:info).with("Workflow #{workflow_id} has completed successfully.")
      workflow.job_completed(:job_d)
    end
  end

  describe "#start_initial_jobs" do
    it "starts jobs with no dependencies and skips completed ones" do
      allow(workflow).to receive(:read_progress).and_return({ job_a: "completed" })
      expect(workflow).to receive(:enqueue_job).with(:job_b).once
      expect(workflow).not_to receive(:enqueue_job).with(:job_a)
      workflow.execute
    end
  end

  describe "#trigger_next_jobs" do
    it "triggers jobs when their dependencies are met" do
      allow(workflow).to receive(:read_progress).and_return({ job_a: "completed" })
      expect(workflow).to receive(:enqueue_job).with(:job_b).once
      expect(workflow).to receive(:enqueue_job).with(:job_c).once
      workflow.job_completed(:job_a)
    end

    it "does not trigger jobs if dependencies are not fully satisfied" do
      allow(workflow).to receive(:read_progress).and_return({ job_b: "in_progress" })
      expect(workflow).not_to receive(:enqueue_job).with(:job_d)
      workflow.job_completed(:job_b)
    end
  end

  describe "#cache_dependencies" do
    it "writes dependencies and initial progress to Rails cache" do
      expect(Rails.cache).to receive(:write).with("workflow:#{workflow_id}:dependencies", dependencies.to_json)
      expect(Rails.cache).to receive(:write).with("workflow:#{workflow_id}:progress", {}.to_json)
      workflow.execute
    end
  end
end
