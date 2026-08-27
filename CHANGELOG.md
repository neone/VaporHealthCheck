# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-08-26

### Added

- `/health` response now includes `version`, `commit`, `started_at` (ISO-8601) and
  `uptime_seconds` (whole seconds since `started_at`)
- `HealthCheckConfiguration.version` (default: `APP_VERSION` environment variable)
  and `HealthCheckConfiguration.commit` (default: `GIT_SHA` environment variable);
  both fields are omitted from the response when unset
- `HealthCheckConfiguration.startedAt`, captured when the configuration is created
  (normally at `registerHealthCheck(configuration:)`)
- `HealthCheckConfiguration.failOnDegraded` (default: `false`); when enabled,
  a `degraded` or `unavailable` status is served with HTTP 503 and the same body.
  Intended for readiness probes only; liveness probes would restart-loop on
  Postgres loss
- Simple `/health` endpoint for Vapor 4+ applications
- PostgreSQL database connectivity health checking
- Automatic health status determination (ready, degraded, unavailable)
- Structured JSON response format
- Configurable health check behavior via `HealthCheckConfiguration`
- One-line integration with `registerHealthCheck()` method
- Async/await support with Swift 6.0
- Strict concurrency checking support
- Database connection timeout (5 seconds)
- Comprehensive unit and integration tests
- Full API documentation
- Support for disabling database health checks

### Changed

- `HealthCheckController.healthCheck(req:)` now returns `Response` (instead of
  `HealthCheckResponse`) so the HTTP status can vary with `failOnDegraded`
- `HealthCheckResponse.init` requires a `startedAt: Date` argument

### Features

- **HealthCheckController**: Handles HTTP requests to `/health` endpoint
- **DatabaseHealthChecker**: Performs database connectivity checks with timeout
- **HealthCheckConfiguration**: Configuration structure for customizing behavior
- **Application+HealthCheck**: Convenient extension method for registration

### Documentation

- Comprehensive README with usage examples
- Integration examples for Kubernetes and Docker
- Contributing guidelines
- Security policy
- MIT License

### Technical Details

- Swift 6.0+ compatibility
- Vapor 4.110.1+ support
- Fluent 4.9.0+ support
- macOS 13+ requirement
- Strict concurrency enabled
- Type-safe response models

[Unreleased]: https://github.com/YOUR-USERNAME/VaporHealthCheck/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/YOUR-USERNAME/VaporHealthCheck/releases/tag/v1.0.0
