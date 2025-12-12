import Vapor
import Fluent

/// Controller handling health check requests
public struct HealthCheckController: RouteCollection, Sendable {
    
    private let databaseHealthChecker = DatabaseHealthChecker()
    
    public init() {}
    
    public func boot(routes: RoutesBuilder) throws {
        routes.get("health", use: healthCheck)
    }
    
    /// Handle the /health endpoint request
    /// - Parameter req: The incoming request
    /// - Returns: A health check response with application and database status
    public func healthCheck(req: Request) async throws -> HealthCheckResponse {
        // Retrieve configuration from application storage
        guard let configuration = req.application.healthCheckConfiguration else {
            throw Abort(.internalServerError, reason: "Health check not configured")
        }
        
        // Check database connection status if enabled
        let databaseStatus: DatabaseConnectionStatus
        if configuration.enableDatabaseCheck {
            // Get the default database
            if let database = req.db as? Database {
                databaseStatus = await databaseHealthChecker.checkPostgresConnection(on: database)
            } else {
                databaseStatus = .notConfigured
            }
        } else {
            databaseStatus = .notConfigured
        }
        
        // Determine overall application health status
        let overallStatus: HealthStatus
        switch databaseStatus {
        case .ready, .notConfigured:
            overallStatus = .ready
        case .unavailable:
            overallStatus = .degraded
        }
        
        // Build and return the response
        return HealthCheckResponse(
            status: overallStatus,
            application: configuration.applicationName,
            postgresConnection: databaseStatus,
            timestamp: Date()
        )
    }
}
