# frozen_string_literal: true

require "sidekhestra"

RSpec.describe Sidekhestra::Workflow do
  let(:workflow) { Sidekhestra::Workflow.new }

  it "adds and executes steps in the correct order" do
    job_class = class_double("Sidekhestra::JobWorker", perform_async: nil)
    workflow.add_step("Step 1", job_class)
    workflow.add_step("Step 2", job_class, dependencies: ["Step 1"])

    workflow.execute

    expect(job_class).to have_received(:perform_async).twice
  end

  it "skips steps with unmet dependencies" do
    job_class = class_double("Sidekhestra::JobWorker", perform_async: nil)
    workflow.add_step("Step 2", job_class, dependencies: ["Step 1"])

    workflow.execute

    expect(job_class).not_to have_received(:perform_async)
  end
end
