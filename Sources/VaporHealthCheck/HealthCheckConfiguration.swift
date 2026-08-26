import Vapor

// MARK: - Health Status Enumerations

/// Overall health status of the application
public enum HealthStatus: String, Codable, Sendable {
    case ready = "ready"
    case degraded = "degraded"
    case unavailable = "unavailable"
}

/// Database connection status
public enum DatabaseConnectionStatus: String, Codable, Sendable {
    case ready = "ready"
    case unavailable = "unavailable"
    case notConfigured = "not_configured"
}

// MARK: - Health Check Response

/// Response structure for the /health endpoint
public struct HealthCheckResponse: Content {
    public let status: String
    public let application: String
    public let postgresConnection: String
    public let timestamp: String
    /// Build/version identifier of the running application (`APP_VERSION` by default).
    /// Omitted from the JSON body when not configured.
    public let version: String?
    /// Source-control revision of the running application (`GIT_SHA` by default).
    /// Omitted from the JSON body when not configured.
    public let commit: String?
    /// ISO-8601 instant at which the health check was registered (process start).
    public let startedAt: String
    /// Whole seconds elapsed since `startedAt`.
    public let uptimeSeconds: Int

    enum CodingKeys: String, CodingKey {
        case status
        case application
        case postgresConnection = "postgres_connection"
        case timestamp
        case version
        case commit
        case startedAt = "started_at"
        case uptimeSeconds = "uptime_seconds"
    }

    public init(
        status: HealthStatus,
        application: String,
        postgresConnection: DatabaseConnectionStatus,
        timestamp: Date = Date(),
        version: String? = nil,
        commit: String? = nil,
        startedAt: Date
    ) {
        let formatter = ISO8601DateFormatter()
        self.status = status.rawValue
        self.application = application
        self.postgresConnection = postgresConnection.rawValue
        self.timestamp = formatter.string(from: timestamp)
        self.version = version
        self.commit = commit
        self.startedAt = formatter.string(from: startedAt)
        self.uptimeSeconds = max(0, Int(timestamp.timeIntervalSince(startedAt)))
    }
}

// MARK: - Configuration

/// Configuration for the health check functionality
public struct HealthCheckConfiguration: Sendable {
    /// Environment variable consulted for the default `version` value.
    public static let versionEnvironmentKey = "APP_VERSION"

    /// Environment variable consulted for the default `commit` value.
    public static let commitEnvironmentKey = "GIT_SHA"

    /// The name of the application to be returned in the health check response
    public let applicationName: String

    /// Whether to perform database connectivity checks
    public let enableDatabaseCheck: Bool

    /// Build/version identifier reported as `version`. Defaults to the `APP_VERSION`
    /// environment variable; `nil` omits the field from the response.
    public let version: String?

    /// Source-control revision reported as `commit`. Defaults to the `GIT_SHA`
    /// environment variable; `nil` omits the field from the response.
    public let commit: String?

    /// Whether a `degraded` or `unavailable` overall status should be reported with
    /// HTTP 503 Service Unavailable instead of 200 OK. The JSON body is identical in
    /// both cases.
    ///
    /// - Important: Enable this for **readiness** probes only. Wiring a 503-on-degraded
    ///   endpoint into a Kubernetes **liveness** probe will restart-loop every pod whenever
    ///   Postgres is unreachable, which makes an outage worse rather than better. Liveness
    ///   probes should keep the default (`false`) or point at a database-free registration
    ///   (`enableDatabaseCheck: false`).
    public let failOnDegraded: Bool

    /// The instant this configuration was created, reported as `started_at` and used to
    /// derive `uptime_seconds`. Because the configuration is normally built inline in
    /// `registerHealthCheck(configuration:)`, this is effectively the process start time.
    public let startedAt: Date

    /// Initialize a new health check configuration
    /// - Parameters:
    ///   - applicationName: The name of the application
    ///   - enableDatabaseCheck: Whether to check database connectivity (default: true)
    ///   - version: Build/version identifier (default: `APP_VERSION` environment variable)
    ///   - commit: Source-control revision (default: `GIT_SHA` environment variable)
    ///   - failOnDegraded: Respond with 503 when the status is not `ready` (default: false).
    ///     Readiness probes only; see ``failOnDegraded``.
    ///   - startedAt: Process start instant used for `started_at` / `uptime_seconds`
    ///     (default: now, i.e. the moment of registration)
    public init(
        applicationName: String,
        enableDatabaseCheck: Bool = true,
        version: String? = Environment.get(HealthCheckConfiguration.versionEnvironmentKey),
        commit: String? = Environment.get(HealthCheckConfiguration.commitEnvironmentKey),
        failOnDegraded: Bool = false,
        startedAt: Date = Date()
    ) {
        self.applicationName = applicationName
        self.enableDatabaseCheck = enableDatabaseCheck
        self.version = version
        self.commit = commit
        self.failOnDegraded = failOnDegraded
        self.startedAt = startedAt
    }
}

// MARK: - Application Storage

extension Application {
    /// Storage key for HealthCheckConfiguration
    struct HealthCheckConfigurationKey: StorageKey {
        typealias Value = HealthCheckConfiguration
    }

    /// Access the health check configuration from application storage
    public var healthCheckConfiguration: HealthCheckConfiguration? {
        get {
            self.storage[HealthCheckConfigurationKey.self]
        }
        set {
            self.storage[HealthCheckConfigurationKey.self] = newValue
        }
    }
}
