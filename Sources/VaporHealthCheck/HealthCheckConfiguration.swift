import Vapor

// MARK: - Health Status Enumerations

/// Overall health status of the application
public enum HealthStatus: String, Codable {
    case ready = "ready"
    case degraded = "degraded"
    case unavailable = "unavailable"
}

/// Database connection status
public enum DatabaseConnectionStatus: String, Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case status
        case application
        case postgresConnection = "postgres_connection"
        case timestamp
    }
    
    public init(
        status: HealthStatus,
        application: String,
        postgresConnection: DatabaseConnectionStatus,
        timestamp: Date = Date()
    ) {
        self.status = status.rawValue
        self.application = application
        self.postgresConnection = postgresConnection.rawValue
        self.timestamp = ISO8601DateFormatter().string(from: timestamp)
    }
}

// MARK: - Configuration

/// Configuration for the health check functionality
public struct HealthCheckConfiguration: Sendable {
    /// The name of the application to be returned in the health check response
    public let applicationName: String
    
    /// Whether to perform database connectivity checks
    public let enableDatabaseCheck: Bool
    
    /// Initialize a new health check configuration
    /// - Parameters:
    ///   - applicationName: The name of the application
    ///   - enableDatabaseCheck: Whether to check database connectivity (default: true)
    public init(applicationName: String, enableDatabaseCheck: Bool = true) {
        self.applicationName = applicationName
        self.enableDatabaseCheck = enableDatabaseCheck
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
