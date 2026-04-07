# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- PID file management and `stop` command for graceful server shutdown

## [0.1.0] - 2026-04-07

### Added

- Core Liquid template rendering engine with mock data support
- Browser-based preview server using Sinatra
- CLI commands (`start`, `stop`) via Thor
- File watching with auto-reload using Listen
- Section and snippet template support
- Unit tests and integration tests with RSpec
- CI pipeline with GitHub Actions (Ruby 3.2 - 4.0)
