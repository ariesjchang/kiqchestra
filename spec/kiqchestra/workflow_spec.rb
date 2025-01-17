# frozen_string_literal: true

require "spec_helper"
require "kiqchestra/config"
require "kiqchestra/default_workflow_store"
require "kiqchestra/redis_client"

RSpec.describe Kiqchestra::Workflow do
  let(:workflow_id) { "test_workflow1" }
  let(:store) { Kiqchestra::DefaultWorkflowStore.new }

  let(:a_job_args) { [] }
  let(:b_job_args) { ["arg1"] }
  let(:c_job_args) { [] }
  let(:d_job_args) { ["arg2", 3] }
  let(:metadata) do
    {
      a_job: { deps: [], args: a_job_args },
      b_job: { deps: [:a_job], args: b_job_args },
      c_job: { deps: [:a_job], args: c_job_args },
      d_job: { deps: %i[b_job c_job], args: d_job_args }
    }
  end
  let(:workflow) { described_class.new(workflow_id, metadata) }

  let(:job_class_a) do
    Class.new(Kiqchestra::BaseJob) do
      def perform_job(*_args)
        sleep 1
      end
    end
  end

  let(:job_class_b) do
    Class.new(Kiqchestra::BaseJob) do
      def perform_job(*_args)
        sleep 1
      end
    end
  end

  let(:job_class_c) do
    Class.new(Kiqchestra::BaseJob) do
      def perform_job(*_args)
        sleep 1
      end
    end
  end

  let(:job_class_d) do
    Class.new(Kiqchestra::BaseJob) do
      def perform_job(*_args)
        sleep 1
      end
    end
  end

  before do
    Object.const_set(:AJob, job_class_a) unless Object.const_defined?(:AJob)
    Object.const_set(:BJob, job_class_b) unless Object.const_defined?(:BJob)
    Object.const_set(:CJob, job_class_c) unless Object.const_defined?(:CJob)
    Object.const_set(:DJob, job_class_d) unless Object.const_defined?(:DJob)

    allow(Kiqchestra).to receive_message_chain(:config, :store).and_return(store)

    allow(Sidekiq.logger).to receive(:info)
    allow(Sidekiq.logger).to receive(:error)
  end

  after do
    Object.send(:remove_const, :AJob) if Object.const_defined?(:AJob)
    Object.send(:remove_const, :BJob) if Object.const_defined?(:BJob)
    Object.send(:remove_const, :CJob) if Object.const_defined?(:CJob)
    Object.send(:remove_const, :DJob) if Object.const_defined?(:DJob)

    # Clear Redis keys before each test
    Redis.new.flushdb
  end

  describe "#initialize" do
    it "validates and stores metadata" do
      expect { workflow }.not_to raise_error
      stored_metadata = store.read_metadata(workflow_id)

      # Normalize stored metadata to symbols for comparison
      normalized_metadata = stored_metadata.transform_keys(&:to_sym).transform_values do |value|
        {
          deps: value["deps"].map(&:to_sym),
          args: value["args"]
        }
      end

      expect(normalized_metadata).to eq(metadata)
    end

    it "raises an error for invalid metadata" do
      invalid_metadata = { a_job: "invalid_data" }
      expect do
        described_class.new(workflow_id, invalid_metadata)
      end.to raise_error(ArgumentError, /Metadata for a_job must be a hash/)
    end
  end

  describe "#execute" do
    context "when dependencies are unmet" do
      before do
        store.write_progress(workflow_id, { a_job: "in_progress" })
      end

      it "does not enqueue dependent jobs" do
        expect(workflow).not_to receive(:enqueue_job).with(:b_job, b_job_args)
        expect(workflow).not_to receive(:enqueue_job).with(:c_job, c_job_args)
        expect(workflow).not_to receive(:enqueue_job).with(:d_job, d_job_args)
        workflow.execute
      end
    end

    context "when jobs are ready to execute" do
      it "enqueues jobs with no dependencies" do
        expect(workflow).to receive(:enqueue_job).with(:a_job, a_job_args)
        workflow.execute
      end

      context "when a_job is complete" do
        before do
          store.write_progress(workflow_id, { a_job: "complete" })
        end

        it "enqueues jobs with only a_job as dependencies" do
          expect(workflow).to receive(:enqueue_job).with(:b_job, b_job_args)
          expect(workflow).to receive(:enqueue_job).with(:c_job, c_job_args)
          workflow.execute
        end
      end
    end

    context "when all jobs are complete" do
      before do
        store.write_progress(workflow_id, {
                               "a_job" => "complete",
                               "b_job" => "complete",
                               "c_job" => "complete",
                               "d_job" => "complete"
                             })
      end

      it "runs conclude_workflow" do
        expect(workflow).to receive(:conclude_workflow)
        workflow.execute
      end
    end
  end

  describe "#handle_completed_job" do
    context "when a job completes" do
      it "updates progress to mark a_job as complete" do
        expect(store.read_progress(workflow_id)).to be_empty
        workflow.handle_completed_job(:a_job)
        progress = store.read_progress(workflow_id)
        expect(progress["a_job"]).to eq("complete")
      end

      it "enqueues dependent jobs" do
        expect(workflow).to receive(:enqueue_job).with(:b_job, b_job_args)
        expect(workflow).to receive(:enqueue_job).with(:c_job, c_job_args)
        workflow.handle_completed_job(:a_job)
      end
    end
  end

  describe "#enqueue_job" do
    it "enqueues a job and updates progress" do
      expect(BJob).to receive(:perform_async).with(workflow_id, *b_job_args)
      workflow.send(:enqueue_job, :b_job, b_job_args)
    end

    it "updates progress" do
      expect(store).to receive(:write_progress).with(workflow_id, { b_job: "in_progress" })
      workflow.send(:enqueue_job, :b_job, b_job_args)
    end

    it "raises an error for undefined job classes" do
      expect do
        workflow.send(:enqueue_job, :undefined_job)
      end.to raise_error(RuntimeError, /Class for job 'undefined_job' not defined/)
    end
  end

  describe "#ready_to_execute?" do
    it "returns true when all dependencies are complete" do
      progress = { "a_job" => "complete", "b_job" => "complete" }
      expect(workflow.send(:ready_to_execute?, %i[a_job b_job], progress)).to be true
    end

    it "returns false when any dependency is not completed" do
      progress = { "a_job" => "complete", "b_job" => "in_progress" }
      expect(workflow.send(:ready_to_execute?, %i[a_job b_job], progress)).to be false
    end
  end

  describe "#workflow_complete?" do
    context "when all jobs are complete" do
      before do
        store.write_progress(workflow_id, {
                               "a_job" => "complete",
                               "b_job" => "complete",
                               "c_job" => "complete",
                               "d_job" => "complete"
                             })
      end

      it "returns true" do
        expect(workflow.send(:workflow_complete?)).to be true
      end
    end

    context "when not all jobs are complete" do
      before do
        store.write_progress(workflow_id, {
                               "job_a" => "complete",
                               "job_b" => "in_progress",
                               "job_c" => "not_started"
                             })
      end

      it "returns false" do
        expect(workflow.send(:workflow_complete?)).to be false
      end
    end
  end
end
