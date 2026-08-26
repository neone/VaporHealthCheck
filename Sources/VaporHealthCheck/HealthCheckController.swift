import Vapor
import Fluent

/// Controller handling health check requests
public struct HealthCheckController: RouteCollection, Sendable {

    /// Resolves the database connection status for a request.
    typealias DatabaseStatusProvider = @Sendable (Request) async -> DatabaseConnectionStatus

    private let databaseStatusProvider: DatabaseStatusProvider

    public init() {
        let databaseHealthChecker = DatabaseHealthChecker()
        self.init { req in
            // Ping the application's default database
            await databaseHealthChecker.checkPostgresConnection(on: req.db)
        }
    }

    /// Internal initializer allowing tests to substitute the database probe.
    init(databaseStatusProvider: @escaping DatabaseStatusProvider) {
        self.databaseStatusProvider = databaseStatusProvider
    }

    public func boot(routes: RoutesBuilder) throws {
        routes.get("health", use: healthCheck)
    }

    /// Handle the /health endpoint request
    /// - Parameter req: The incoming request
    /// - Returns: A health check response with application and database status.
    ///   The HTTP status is 200 unless `failOnDegraded` is enabled and the overall
    ///   status is not `ready`, in which case it is 503 with the same body.
    public func healthCheck(req: Request) async throws -> Response {
        // Retrieve configuration from application storage
        guard let configuration = req.application.healthCheckConfiguration else {
            throw Abort(.internalServerError, reason: "Health check not configured")
        }

        // Check database connection status if enabled
        let databaseStatus: DatabaseConnectionStatus
        if configuration.enableDatabaseCheck {
            databaseStatus = await databaseStatusProvider(req)
        } else {
            databaseStatus = .notConfigured
        }

        // Determine overall application health status
        let overallStatus = Self.overallStatus(for: databaseStatus)

        // Build the response body
        let body = HealthCheckResponse(
            status: overallStatus,
            application: configuration.applicationName,
            postgresConnection: databaseStatus,
            timestamp: Date(),
            version: configuration.version,
            commit: configuration.commit,
            startedAt: configuration.startedAt
        )

        let httpStatus = Self.httpStatus(for: overallStatus, configuration: configuration)
        return try await body.encodeResponse(status: httpStatus, for: req)
    }

    /// Derive the overall application status from the database status.
    static func overallStatus(for databaseStatus: DatabaseConnectionStatus) -> HealthStatus {
        switch databaseStatus {
        case .ready, .notConfigured:
            return .ready
        case .unavailable:
            return .degraded
        }
    }

    /// Map the overall status to an HTTP status code, honouring `failOnDegraded`.
    static func httpStatus(
        for overallStatus: HealthStatus,
        configuration: HealthCheckConfiguration
    ) -> HTTPStatus {
        switch overallStatus {
        case .ready:
            return .ok
        case .degraded, .unavailable:
            return configuration.failOnDegraded ? .serviceUnavailable : .ok
        }
    }
}
