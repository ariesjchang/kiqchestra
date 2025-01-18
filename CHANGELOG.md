# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2025-01-17

### Added

- Added Redis service for GitHub Actions tests.

## [1.0.0] - 2025-01-17

### Added

- Initial release of Kiqchestra, a Sidekiq-based job orchestration framework.
- Support for defining workflows with job dependencies.
- Redis-based default metadata store for job and workflow progress tracking.
- Ability to implement custom stores for workflow metadata and progress.
- Progress tracking for workflows.

### Documentation

- Comprehensive README with usage examples, installation instructions, and contribution guidelines.