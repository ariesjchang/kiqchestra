require "spec_helper"

RSpec.describe Kiqchestra::BaseJob, type: :worker do
  let(:workflow_id) { 'workflow_123' }
  let(:args) { ['arg1', 'arg2'] }
  let(:job_class) do
    Class.new(Kiqchestra::BaseJob) do
      def perform_job(*args)
        sleep 1
      end
    end
  end

  before do
    Object.const_set(:TestJob, job_class)
  end

  let(:job_instance) { TestJob.new }

  before do
    allow(Sidekiq.logger).to receive(:info)
    allow(Sidekiq.logger).to receive(:error)
  end

  describe '#perform' do
    context 'when job completes successfully' do
      it 'calls perform_job and handles completed job' do
        expect(job_instance).to receive(:perform_job).with(*args)
        expect { job_instance.perform(workflow_id, *args) }.not_to raise_error
      end

      it 'logs info message for job start' do
        job_instance.perform(workflow_id, *args)
        expect(Sidekiq.logger).to have_received(:info).with(/Starting job/)
      end

      it 'logs info message for job completion' do
        job_instance.perform(workflow_id, *args)
        expect_any_instance_of(Kiqchestra::Workflow) do |workflow|
          expect(workflow).to receive(:handle_completed_job)
        end
      end
    end

    context 'when job raises an error' do
      let(:error_message) { 'Something went wrong' }

      before do
        allow(job_instance).to receive(:perform_job).and_raise(StandardError, error_message)
      end

      it 'logs error message when job fails' do
        expect { job_instance.perform(workflow_id, *args) }.to raise_error(StandardError)
        expect(Sidekiq.logger).to have_received(:error).with(/failed:/)
      end
    end
  end
end
