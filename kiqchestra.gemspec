# frozen_string_literal: true

require_relative "lib/kiqchestra/version"

Gem::Specification.new do |spec|
  spec.name = "kiqchestra"
  spec.version = Kiqchestra::VERSION
  spec.authors = ["aries"]
  spec.email = ["edwardjhchang@gmail.com"]

  spec.summary = "Job Workflow Orchestration Layer for Sidekiq"
  spec.description = "Kiqchestra enhances the power of Sidekiq by introducing a job orchestration framework " \
                     "designed to handle complex workflows with ease and efficiency."
  spec.homepage = "https://github.com/ariesjchang/kiqchestra."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = "https://github.com/ariesjchang/kiqchestra"
  spec.metadata["source_code_uri"] = "https://github.com/ariesjchang/kiqchestra"
  spec.metadata["changelog_uri"] = "https://github.com/ariesjchang/kiqchestra/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile]) ||
        f.end_with?(".gem") # Explicitly reject .gem files
    end
  end

  # Bindir and executables
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", "~> 6.5.5"
end
