import Vapor

extension Application {
    /// Register the health check endpoint with the application
    /// 
    /// This method configures the health check functionality and registers the `/health` 
    /// endpoint as an unauthenticated route. Call this method in your `configure.swift` 
    /// after setting up your database configuration.
    ///
    /// Example:
    /// ```swift
    /// app.registerHealthCheck(
    ///     configuration: HealthCheckConfiguration(
    ///         applicationName: "my-application"
    ///     )
    /// )
    /// ```
    ///
    /// - Parameter configuration: Configuration for the health check
    public func registerHealthCheck(configuration: HealthCheckConfiguration) {
        // Store configuration in application storage for access by the controller
        self.healthCheckConfiguration = configuration
        
        // Register the health check controller routes
        do {
            try self.routes.register(collection: HealthCheckController())
            self.logger.info("Health check endpoint registered at /health")
        } catch {
            self.logger.error("Failed to register health check routes: \(error)")
        }
    }
}
