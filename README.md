# VaporHealthCheck

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![Vapor 4](https://img.shields.io/badge/Vapor-4.0+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

A production-ready Swift package that provides a simple, unauthenticated `/health` endpoint for Vapor 4+ applications with comprehensive application and database health status monitoring.

## Features

- 🚀 Simple one-line integration with any Vapor 4+ application
- 🏥 Automatic PostgreSQL connection health checking
- 📊 Structured JSON response format
- 🏷️ Reports build `version`, `commit`, `started_at` and `uptime_seconds`
- 🚦 Opt-in HTTP 503 on degraded status for readiness probes
- 🔓 Unauthenticated endpoint for monitoring tools
- ⚡ Async/await support with Swift 6.0
- 🧪 Fully tested and production-ready

## Requirements

- Swift 6.0+
- Vapor 4.110.1+
- Fluent 4.9.0+
- macOS 13+

## Installation

Add VaporHealthCheck to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR-USERNAME/VaporHealthCheck.git", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "VaporHealthCheck", package: "VaporHealthCheck")
    ]
)
```

> **Note:** Replace `YOUR-USERNAME` with the actual GitHub username or organization where you publish this package.

## Usage

### Basic Setup

In your `configure.swift`, register the health check after configuring your database:

```swift
import Vapor
import VaporHealthCheck

public func configure(_ app: Application) async throws {
    // Configure your database
    app.databases.use(.postgres(/*...*/), as: .psql)
    
    // Register health check
    app.registerHealthCheck(
        configuration: HealthCheckConfiguration(
            applicationName: "my-application"
        )
    )
    
    // Continue with other configuration...
}
```

That's it! The `/health` endpoint is now available.

### Configuration Options

```swift
HealthCheckConfiguration(
    applicationName: "my-application",  // Your application name
    enableDatabaseCheck: true,          // Enable/disable database health checks (default: true)
    version: "1.4.2",                   // Reported as `version` (default: APP_VERSION env var)
    commit: "3f9c1d2",                  // Reported as `commit` (default: GIT_SHA env var)
    failOnDegraded: false,              // Respond 503 when not `ready` (default: false; readiness probes only)
    startedAt: Date()                   // Reported as `started_at`; drives `uptime_seconds` (default: now)
)
```

`version` and `commit` fall back to the `APP_VERSION` and `GIT_SHA` environment
variables, so a container image built with

```dockerfile
ENV APP_VERSION=1.4.2 GIT_SHA=3f9c1d2
```

reports them with no code changes. When neither the parameter nor the environment
variable is set, the field is omitted from the response.

`startedAt` is captured when the configuration is created, which is normally the
`registerHealthCheck(configuration:)` call in `configure.swift`, i.e. process start.

## Response Format

### Successful Response (200 OK)

```json
{
    "status": "ready",
    "application": "my-application",
    "postgres_connection": "ready",
    "timestamp": "2026-08-26T18:30:00Z",
    "version": "1.4.2",
    "commit": "3f9c1d2",
    "started_at": "2026-08-26T12:00:00Z",
    "uptime_seconds": 23400
}
```

`version` and `commit` are omitted when not configured (see
[Configuration Options](#configuration-options)).

### Degraded Response (200 OK, or 503 with `failOnDegraded`)

When the database is unavailable but the application is running:

```json
{
    "status": "degraded",
    "application": "my-application",
    "postgres_connection": "unavailable",
    "timestamp": "2026-08-26T18:30:00Z",
    "version": "1.4.2",
    "commit": "3f9c1d2",
    "started_at": "2026-08-26T12:00:00Z",
    "uptime_seconds": 23400
}
```

By default this is served with HTTP 200 so that liveness probes keep the process
alive while the database recovers. With `failOnDegraded: true` the same body is served
with HTTP **503 Service Unavailable**, which lets a readiness probe pull the pod out of
rotation. See [Readiness vs. liveness](#readiness-vs-liveness) before enabling it.

### Status Values

- **status**: `ready` | `degraded` | `unavailable`
  - `ready`: All systems operational
  - `degraded`: Application running but database unavailable
  - `unavailable`: Application not functional

- **postgres_connection**: `ready` | `unavailable` | `not_configured`
  - `ready`: Database connection successful
  - `unavailable`: Database connection failed
  - `not_configured`: Database health check disabled

- **version** / **commit**: Free-form strings from configuration or the `APP_VERSION` /
  `GIT_SHA` environment variables; omitted when unset
- **started_at**: ISO-8601 instant the health check was registered (process start)
- **uptime_seconds**: Whole seconds elapsed since `started_at`

## Testing

The package includes comprehensive unit and integration tests. Run tests with:

```bash
swift test
```

## Integration with Monitoring Tools

The `/health` endpoint is designed to work with common monitoring and orchestration tools:

- **Kubernetes**: Use as a liveness/readiness probe
- **Docker**: Use as a healthcheck
- **Load Balancers**: Use for backend health verification
- **Monitoring Services**: Datadog, New Relic, etc.

### Kubernetes Example

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Readiness vs. liveness

`failOnDegraded` changes the HTTP status only; the JSON body is the same either way.

- **Readiness probes** decide whether a pod receives traffic. A 503 while Postgres is
  unreachable is exactly what you want: the pod is removed from the Service until the
  database comes back, and re-added automatically.
- **Liveness probes** decide whether the container is *killed and restarted*. A 503 on
  database loss here would restart every pod in a loop for the duration of a Postgres
  outage, and the restarts do nothing to fix the database.

Enable `failOnDegraded` only if `/health` is used as a readiness probe. If the same
endpoint also backs a liveness probe, keep the default (`false`) so the liveness probe
only fails when the process itself cannot answer.

```swift
app.registerHealthCheck(
    configuration: HealthCheckConfiguration(
        applicationName: "my-application",
        failOnDegraded: true   // readiness probe only
    )
)
```

### Docker Compose Example

```yaml
services:
  app:
    image: your-vapor-app:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## Architecture

The package is designed with simplicity and extensibility in mind:

- **`HealthCheckController`**: Handles HTTP requests to the `/health` endpoint
- **`DatabaseHealthChecker`**: Performs database connectivity checks with timeout support
- **`HealthCheckConfiguration`**: Configuration structure for customizing health check behavior
- **`Application+HealthCheck`**: Extension providing the convenient `registerHealthCheck()` method

## Advanced Usage

### Custom Health Check Logic

While this package focuses on PostgreSQL database health checks, you can extend it or use it alongside custom health checks:

```swift
import Vapor
import VaporHealthCheck

public func configure(_ app: Application) async throws {
    // Configure database
    app.databases.use(.postgres(/*...*/), as: .psql)
    
    // Register standard health check
    app.registerHealthCheck(
        configuration: HealthCheckConfiguration(
            applicationName: "my-application"
        )
    )
    
    // Add custom health endpoints if needed
    app.get("health", "detailed") { req async throws -> DetailedHealthResponse in
        // Your custom health check logic
    }
}
```

### Disabling Database Checks

If you need a health check without database monitoring:

```swift
app.registerHealthCheck(
    configuration: HealthCheckConfiguration(
        applicationName: "my-application",
        enableDatabaseCheck: false
    )
)
```

## Troubleshooting

### Health Check Returns 500

If the health check endpoint returns a 500 error, ensure you've called `registerHealthCheck()` after configuring your application in `configure.swift`.

### Database Always Shows "unavailable"

- Verify your database is configured correctly with Fluent
- Check that your database connection settings are correct
- Ensure the database is accessible from your application
- Check the application logs for specific connection errors

### Timeout Issues

The default timeout for database checks is 5 seconds. If your database is slow to respond, you may see intermittent `unavailable` statuses. Consider optimizing your database or network configuration.

## Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository** on GitHub
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes** and ensure tests pass (`swift test`)
4. **Commit your changes** (`git commit -m 'Add amazing feature'`)
5. **Push to the branch** (`git push origin feature/amazing-feature`)
6. **Open a Pull Request**

### Development Guidelines

- Follow Swift API Design Guidelines
- Maintain compatibility with Swift 6.0+ and Vapor 4+
- Add tests for new features
- Update documentation for any API changes
- Ensure code compiles without warnings
- Use strict concurrency checking

## Versioning

This project follows [Semantic Versioning](https://semver.org/). For available versions, see the [tags on this repository](https://github.com/YOUR-USERNAME/VaporHealthCheck/tags).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors

- Created by the VaporHealthCheck Contributors

## Acknowledgments

- Built for the [Vapor](https://vapor.codes) web framework
- Inspired by common health check patterns in microservices architecture
- Thanks to the Vapor community for their excellent framework and support

## Support

- **Issues**: For bug reports and feature requests, please [open an issue](https://github.com/YOUR-USERNAME/VaporHealthCheck/issues)
- **Discussions**: For questions and general discussion, use [GitHub Discussions](https://github.com/YOUR-USERNAME/VaporHealthCheck/discussions)
- **Security**: For security vulnerabilities, please see [SECURITY.md](SECURITY.md) for reporting instructions

## Roadmap

Future enhancements being considered:

- Support for additional database types (MySQL, MongoDB, etc.)
- Custom health check providers
- Metrics collection integration
- Health check caching to reduce database load
- Configurable timeout durations

Feedback and suggestions are always welcome!
