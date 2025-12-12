# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release preparation

## [1.0.0] - TBD

### Added
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
