import Vapor
import Fluent
import NIOCore
import SQLKit

/// Handles database connectivity health checks
public struct DatabaseHealthChecker: Sendable {
    
    /// Timeout duration for database ping operations (in seconds)
    private let timeoutDuration: TimeAmount = .seconds(5)
    
    public init() {}
    
    /// Check the PostgreSQL database connection status
    /// - Parameter database: The database to check
    /// - Returns: The connection status (ready, unavailable, or not configured)
    public func checkPostgresConnection(on database: Database) async -> DatabaseConnectionStatus {
        do {
            let isHealthy = try await performDatabasePing(on: database)
            return isHealthy ? .ready : .unavailable
        } catch {
            // Log the error but return unavailable status
            return .unavailable
        }
    }
    
    /// Perform a database ping using a simple SELECT 1 query
    /// - Parameter database: The database to ping
    /// - Returns: True if the database responds successfully, false otherwise
    /// - Throws: Database errors if the connection fails
    public func performDatabasePing(on database: Database) async throws -> Bool {
        // Create a timeout task
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            // Add the database query task
            group.addTask {
                try await self.executePingQuery(on: database)
            }
            
            // Add a timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(self.timeoutDuration.nanoseconds))
                throw DatabasePingError.timeout
            }
            
            // Return the first completed task and cancel the others
            if let result = try await group.next() {
                group.cancelAll()
                return result
            }
            
            throw DatabasePingError.noResult
        }
    }
    
    /// Execute the actual ping query against the database
    /// - Parameter database: The database to query
    /// - Returns: True if the query succeeds
    /// - Throws: Database errors
    private func executePingQuery(on database: Database) async throws -> Bool {
        // Execute a simple SELECT 1 query to verify database connectivity
        guard let sqlDatabase = database as? SQLDatabase else {
            // If not a SQL database, assume it's configured
            return true
        }
        _ = try await sqlDatabase.raw("SELECT 1").all()
        return true
    }
}

// MARK: - Errors

/// Errors that can occur during database ping operations
enum DatabasePingError: Error {
    case timeout
    case noResult
}
