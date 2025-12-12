import XCTVapor
@testable import VaporHealthCheck

final class HealthCheckTests: XCTestCase {
    
    var app: Application!
    
    override func setUp() async throws {
        app = try await Application.make(.testing)
    }
    
    override func tearDown() async throws {
        try await app.asyncShutdown()
        app = nil
    }
    
    // MARK: - Response Structure Tests
    
    func testHealthCheckEndpointReturns200() async throws {
        // Configure health check
        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "test-app",
                enableDatabaseCheck: false
            )
        )
        
        // Test the endpoint
        let response = try await app.sendRequest(.GET, "/health")
        XCTAssertEqual(response.status, .ok)
    }
    
    func testHealthCheckResponseStructure() async throws {
        // Configure health check
        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "test-app",
                enableDatabaseCheck: false
            )
        )
        
        // Test the endpoint
        let response = try await app.sendRequest(.GET, "/health")
        XCTAssertEqual(response.status, .ok)
        
        let healthResponse = try response.content.decode(HealthCheckResponse.self)
        XCTAssertEqual(healthResponse.application, "test-app")
        XCTAssertEqual(healthResponse.status, "ready")
        XCTAssertEqual(healthResponse.postgresConnection, "not_configured")
        XCTAssertFalse(healthResponse.timestamp.isEmpty)
    }
    
    func testHealthCheckResponseContainsApplicationName() async throws {
        // Configure with custom application name
        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "my-custom-app",
                enableDatabaseCheck: false
            )
        )
        
        let response = try await app.sendRequest(.GET, "/health")
        let healthResponse = try response.content.decode(HealthCheckResponse.self)
        XCTAssertEqual(healthResponse.application, "my-custom-app")
    }
    
    func testHealthCheckEndpointIsUnauthenticated() async throws {
        // Configure health check
        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "test-app",
                enableDatabaseCheck: false
            )
        )
        
        // Test without any authentication headers
        let response = try await app.sendRequest(.GET, "/health")
        XCTAssertEqual(response.status, .ok)
    }
    
    // MARK: - Timestamp Tests
    
    func testTimestampIsISO8601Format() async throws {
        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "test-app",
                enableDatabaseCheck: false
            )
        )
        
        let response = try await app.sendRequest(.GET, "/health")
        let healthResponse = try response.content.decode(HealthCheckResponse.self)
        
        // Verify timestamp can be parsed as ISO8601
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: healthResponse.timestamp)
        XCTAssertNotNil(date, "Timestamp should be valid ISO8601 format")
    }
    
    // MARK: - Status Tests
    
    func testStatusReadyWhenDatabaseCheckDisabled() async throws {
        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "test-app",
                enableDatabaseCheck: false
            )
        )
        
        let response = try await app.sendRequest(.GET, "/health")
        let healthResponse = try response.content.decode(HealthCheckResponse.self)
        XCTAssertEqual(healthResponse.status, "ready")
        XCTAssertEqual(healthResponse.postgresConnection, "not_configured")
    }
    
    // MARK: - Configuration Tests
    
    func testHealthCheckWithoutConfigurationFails() async throws {
        // Don't register health check, but try to access endpoint
        // The controller should be registered manually for this test
        try app.routes.register(collection: HealthCheckController())
        
        let response = try await app.sendRequest(.GET, "/health")
        XCTAssertEqual(response.status, .internalServerError)
    }
    
    // MARK: - JSON Key Mapping Tests
    
    func testResponseUsesSnakeCaseForPostgresConnection() async throws {
        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "test-app",
                enableDatabaseCheck: false
            )
        )
        
        let response = try await app.sendRequest(.GET, "/health")
        // Check raw JSON contains snake_case key
        let body = try XCTUnwrap(response.body.string)
        XCTAssertTrue(body.contains("postgres_connection"))
        XCTAssertFalse(body.contains("postgresConnection"))
    }
}
