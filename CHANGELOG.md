# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Snippet parameter form now submits via GET with query parameters (page navigation) instead of a JS-driven POST that swapped innerHTML; the Rendered HTML view stays in sync and preview state is bookmarkable/shareable via URL

### Removed

- `POST /api/render/:type/:name` and `GET /api/render/:type/:name` endpoints, along with the 1.5s live-reload polling that depended on them

## [0.1.1] - 2026-04-09

### Added

- PID file management and `stop` command for graceful server shutdown
- CD workflow: GitHub Release auto-creation from CHANGELOG on tag push
- CD workflow: RubyGems publish via manual `workflow_dispatch`

### Changed

- Rename CI workflow file from `test.yml` to `ci.yml`

## [0.1.0] - 2026-04-07

### Added

- Core Liquid template rendering engine with mock data support
- Browser-based preview server using Sinatra
- CLI commands (`start`, `stop`) via Thor
- File watching with auto-reload using Listen
- Section and snippet template support
- Unit tests and integration tests with RSpec
- CI pipeline with GitHub Actions (Ruby 3.2 - 4.0)
