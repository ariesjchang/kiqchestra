# Kiqchestra - Sidekiq Job Orchestration Framework

Kiqchestra is a lightweight Sidekiq-based job orchestration framework that allows you to manage complex job workflows with dependencies between tasks. Unlike traditional background job frameworks, Kiqchestra simplifies job orchestration by allowing jobs to be executed based on the completion of other jobs, ensuring smooth and controlled execution of task sequences.

## Features

- **Job Dependencies**: Easily manage dependency relationship between jobs and ensure they run in the correct order.
- **Progress Tracking**: Track the progress of each job in a workflow. Customizable for your need.

## Installation

Add the following line to your `Gemfile`:

```ruby
gem 'kiqchestra'
```

Run `bundle install` to install the gem.
Alternatively, you can install the gem manually:

```bash
gem install kiqchestra
```

## Configuration

By default, Kiqchestra uses a Redis-backed store (`DefaultWorkflowStore`) that caches workflow metadata and progress for 7 days, but you can provide your own custom store if needed. To use `DefaultWorkflowStore`, make sure to have `ENV[REDIS_URL]` - if not defined, `redis://localhost:6379/0` will be used (see [Kiqchestra::RedisClient](https://github.com/ariesjchang/kiqchestra/blob/main/lib/kiqchestra/redis_client.rb)).

### Customizing WorkflowStore

You can create your own store by subclassing Kiqchestra::WorkflowStore and implementing the required methods (`read_metadata`, `write_metadata`, `read_progress`, `write_progress`).

For example:

```ruby
class MyCustomWorkflowStore < Kiqchestra::WorkflowStore
  def read_metadata(workflow_id)
    # Your implementation
  end

  def write_metadata(workflow_id, metadata)
    # Your implementation
  end

  def read_progress(workflow_id)
    # Your implementation
  end

  def write_progress(workflow_id, progress)
    # Your implementation
  end
end

Kiqchestra.configure do |config|
  config.store = MyCustomWorkflowStore.new
end
```

## Usage

### Defining a Workflow

A workflow is defined by a unique workflow_id and a set of metadata that describes the jobs and their dependencies. The metadata for each job should include:
- `deps`: An array of jobs that must complete before the current job can start.
- `args`: Arguments to be passed to the job.

Here's an example of a workflow metadata definition:

```ruby
metadata = {
  a_job: { deps: [], args: [1, 2, 3] },
  b_job: { deps: [:a_job], args: [4, 5] },
  c_job: { deps: [:a_job], args: nil },
  d_job: { deps: [:b_job, :c_job], args: [6] }
}
```

Make sure each job name corresponds to an actual existing class that is a subclass of `Kiqchestra::BaseJob` (ex. `a_job` would be `AJob`).
You can create and run a workflow by:

```ruby
workflow = Kiqchestra::Workflow.new('workflow_123', metadata)
workflow.execute
```

## Contributing
Contributions to Kiqchestra are welcome! To contribute:

1. Fork the repository.
2. Create a new branch.
3. Make your changes.
4. Run tests.
5. Open a pull request.

## License

Kiqchestra is released under the MIT License.