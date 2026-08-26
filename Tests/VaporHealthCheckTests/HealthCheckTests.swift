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
        XCTAssertTrue(body.contains("started_at"))
        XCTAssertTrue(body.contains("uptime_seconds"))
        XCTAssertFalse(body.contains("startedAt"))
        XCTAssertFalse(body.contains("uptimeSeconds"))
    }

    // MARK: - Version / Commit Tests

    func testVersionAndCommitDefaultToEnvironment() async throws {
        setenv(HealthCheckConfiguration.versionEnvironmentKey, "1.2.3", 1)
        setenv(HealthCheckConfiguration.commitEnvironmentKey, "abc1234", 1)
        defer {
            unsetenv(HealthCheckConfiguration.versionEnvironmentKey)
            unsetenv(HealthCheckConfiguration.commitEnvironmentKey)
        }

        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "test-app",
                enableDatabaseCheck: false
            )
        )

        let response = try await app.sendRequest(.GET, "/health")
        let healthResponse = try response.content.decode(HealthCheckResponse.self)
        XCTAssertEqual(healthResponse.version, "1.2.3")
        XCTAssertEqual(healthResponse.commit, "abc1234")
    }

    func testExplicitVersionAndCommitOverrideEnvironment() async throws {
        setenv(HealthCheckConfiguration.versionEnvironmentKey, "env-version", 1)
        setenv(HealthCheckConfiguration.commitEnvironmentKey, "env-commit", 1)
        defer {
            unsetenv(HealthCheckConfiguration.versionEnvironmentKey)
            unsetenv(HealthCheckConfiguration.commitEnvironmentKey)
        }

        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "test-app",
                enableDatabaseCheck: false,
                version: "9.9.9",
                commit: "deadbeef"
            )
        )

        let response = try await app.sendRequest(.GET, "/health")
        let healthResponse = try response.content.decode(HealthCheckResponse.self)
        XCTAssertEqual(healthResponse.version, "9.9.9")
        XCTAssertEqual(healthResponse.commit, "deadbeef")
    }

    func testVersionAndCommitOmittedWhenUnset() async throws {
        unsetenv(HealthCheckConfiguration.versionEnvironmentKey)
        unsetenv(HealthCheckConfiguration.commitEnvironmentKey)

        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "test-app",
                enableDatabaseCheck: false
            )
        )

        let response = try await app.sendRequest(.GET, "/health")
        let healthResponse = try response.content.decode(HealthCheckResponse.self)
        XCTAssertNil(healthResponse.version)
        XCTAssertNil(healthResponse.commit)

        let body = try XCTUnwrap(response.body.string)
        XCTAssertFalse(body.contains("\"version\""))
        XCTAssertFalse(body.contains("\"commit\""))
    }

    // MARK: - Started At / Uptime Tests

    func testStartedAtAndUptimeReflectRegistrationTime() async throws {
        let startedAt = Date(timeIntervalSinceNow: -125)
        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "test-app",
                enableDatabaseCheck: false,
                startedAt: startedAt
            )
        )

        let response = try await app.sendRequest(.GET, "/health")
        let healthResponse = try response.content.decode(HealthCheckResponse.self)

        let formatter = ISO8601DateFormatter()
        let parsed = try XCTUnwrap(formatter.date(from: healthResponse.startedAt))
        // ISO-8601 output has whole-second precision
        XCTAssertEqual(parsed.timeIntervalSince1970, startedAt.timeIntervalSince1970, accuracy: 1)
        XCTAssertGreaterThanOrEqual(healthResponse.uptimeSeconds, 125)
        XCTAssertLessThan(healthResponse.uptimeSeconds, 135)
    }

    func testStartedAtDefaultsToNow() async throws {
        let before = Date()
        let configuration = HealthCheckConfiguration(
            applicationName: "test-app",
            enableDatabaseCheck: false
        )
        XCTAssertGreaterThanOrEqual(configuration.startedAt, before)
        XCTAssertLessThanOrEqual(configuration.startedAt, Date())
        XCTAssertFalse(configuration.failOnDegraded)
    }

    func testUptimeNeverNegative() {
        let response = HealthCheckResponse(
            status: .ready,
            application: "test-app",
            postgresConnection: .notConfigured,
            timestamp: Date(),
            startedAt: Date(timeIntervalSinceNow: 60)
        )
        XCTAssertEqual(response.uptimeSeconds, 0)
    }

    // MARK: - failOnDegraded Tests

    private func registerDegradedHealthCheck(failOnDegraded: Bool) throws {
        app.healthCheckConfiguration = HealthCheckConfiguration(
            applicationName: "test-app",
            enableDatabaseCheck: true,
            failOnDegraded: failOnDegraded
        )
        try app.routes.register(
            collection: HealthCheckController(databaseStatusProvider: { _ in .unavailable })
        )
    }

    func testDegradedReturns200ByDefault() async throws {
        try registerDegradedHealthCheck(failOnDegraded: false)

        let response = try await app.sendRequest(.GET, "/health")
        XCTAssertEqual(response.status, .ok)

        let healthResponse = try response.content.decode(HealthCheckResponse.self)
        XCTAssertEqual(healthResponse.status, "degraded")
        XCTAssertEqual(healthResponse.postgresConnection, "unavailable")
    }

    func testDegradedReturns503WhenFailOnDegraded() async throws {
        try registerDegradedHealthCheck(failOnDegraded: true)

        let response = try await app.sendRequest(.GET, "/health")
        XCTAssertEqual(response.status, .serviceUnavailable)

        // Body is identical to the 200 path
        let healthResponse = try response.content.decode(HealthCheckResponse.self)
        XCTAssertEqual(healthResponse.status, "degraded")
        XCTAssertEqual(healthResponse.postgresConnection, "unavailable")
        XCTAssertEqual(healthResponse.application, "test-app")
        XCTAssertFalse(healthResponse.startedAt.isEmpty)
    }

    func testReadyReturns200EvenWhenFailOnDegraded() async throws {
        app.healthCheckConfiguration = HealthCheckConfiguration(
            applicationName: "test-app",
            enableDatabaseCheck: true,
            failOnDegraded: true
        )
        try app.routes.register(
            collection: HealthCheckController(databaseStatusProvider: { _ in .ready })
        )

        let response = try await app.sendRequest(.GET, "/health")
        XCTAssertEqual(response.status, .ok)

        let healthResponse = try response.content.decode(HealthCheckResponse.self)
        XCTAssertEqual(healthResponse.status, "ready")
        XCTAssertEqual(healthResponse.postgresConnection, "ready")
    }

    func testDatabaseCheckDisabledIsReadyEvenWhenFailOnDegraded() async throws {
        app.registerHealthCheck(
            configuration: HealthCheckConfiguration(
                applicationName: "test-app",
                enableDatabaseCheck: false,
                failOnDegraded: true
            )
        )

        let response = try await app.sendRequest(.GET, "/health")
        XCTAssertEqual(response.status, .ok)

        let healthResponse = try response.content.decode(HealthCheckResponse.self)
        XCTAssertEqual(healthResponse.status, "ready")
        XCTAssertEqual(healthResponse.postgresConnection, "not_configured")
    }

    func testHTTPStatusMapping() {
        let lenient = HealthCheckConfiguration(applicationName: "a", failOnDegraded: false)
        let strict = HealthCheckConfiguration(applicationName: "a", failOnDegraded: true)

        XCTAssertEqual(HealthCheckController.httpStatus(for: .ready, configuration: lenient), .ok)
        XCTAssertEqual(HealthCheckController.httpStatus(for: .degraded, configuration: lenient), .ok)
        XCTAssertEqual(HealthCheckController.httpStatus(for: .unavailable, configuration: lenient), .ok)

        XCTAssertEqual(HealthCheckController.httpStatus(for: .ready, configuration: strict), .ok)
        XCTAssertEqual(HealthCheckController.httpStatus(for: .degraded, configuration: strict), .serviceUnavailable)
        XCTAssertEqual(HealthCheckController.httpStatus(for: .unavailable, configuration: strict), .serviceUnavailable)
    }
}
