# Contributing to VaporHealthCheck

Thank you for your interest in contributing to VaporHealthCheck! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the behavior
- **Expected behavior** vs actual behavior
- **Code samples** demonstrating the issue
- **Environment details** (Swift version, Vapor version, OS)
- **Stack traces** or error messages if applicable

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the proposed functionality
- **Explain why this enhancement would be useful**
- **Provide code examples** if applicable

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding style** of the project
3. **Add tests** for any new functionality
4. **Update documentation** as needed
5. **Ensure all tests pass** before submitting
6. **Write clear commit messages**

## Development Setup

### Prerequisites

- Swift 6.0 or later
- Xcode 16.0 or later (for macOS development)
- Git

### Getting Started

1. Fork and clone the repository:
```bash
git clone https://github.com/YOUR-USERNAME/VaporHealthCheck.git
cd VaporHealthCheck
```

2. Build the package:
```bash
swift build
```

3. Run tests:
```bash
swift test
```

### Project Structure

```
VaporHealthCheck/
├── Sources/
│   └── VaporHealthCheck/
│       ├── Application+HealthCheck.swift      # Extension for registering health checks
│       ├── DatabaseHealthChecker.swift        # Database connectivity checker
│       ├── HealthCheckConfiguration.swift     # Configuration models
│       └── HealthCheckController.swift        # Route controller
├── Tests/
│   └── VaporHealthCheckTests/
│       └── HealthCheckTests.swift            # Test suite
├── Package.swift                              # Package manifest
└── README.md                                  # Documentation
```

## Coding Guidelines

### Swift Style Guide

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use 4 spaces for indentation (no tabs)
- Maximum line length of 120 characters
- Use meaningful variable and function names
- Add doc comments for public APIs

### Documentation

All public APIs should include documentation comments:

```swift
/// Brief description of what this does
///
/// More detailed explanation if needed, including:
/// - Important behavior notes
/// - Parameter details
/// - Return value information
///
/// Example:
/// ```swift
/// // Example usage
/// ```
///
/// - Parameters:
///   - param1: Description of parameter
///   - param2: Description of parameter
/// - Returns: Description of return value
/// - Throws: Description of errors that can be thrown
public func myFunction(param1: String, param2: Int) throws -> Bool {
    // Implementation
}
```

### Testing

- Write tests for all new functionality
- Maintain or improve code coverage
- Use descriptive test names that explain what is being tested
- Follow the Arrange-Act-Assert pattern

Example test structure:
```swift
func testHealthCheckReturnsReady() async throws {
    // Arrange
    let app = try await Application.make(.testing)
    
    // Act
    try await app.test(.GET, "health") { res in
        // Assert
        XCTAssertEqual(res.status, .ok)
        let response = try res.content.decode(HealthCheckResponse.self)
        XCTAssertEqual(response.status, "ready")
    }
}
```

### Commit Messages

Write clear, concise commit messages:

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues and pull requests when applicable

Example:
```
Add support for MySQL database health checks

- Implement MySQLHealthChecker class
- Add configuration option for MySQL
- Update tests to cover MySQL scenarios
- Update documentation

Closes #123
```

## Testing

### Running Tests

Run all tests:
```bash
swift test
```

Run specific tests:
```bash
swift test --filter HealthCheckTests
```

Run tests with coverage (requires Xcode):
```bash
swift test --enable-code-coverage
```

### Test Requirements

- All new features must include tests
- All tests must pass before merging
- Maintain or improve overall code coverage
- Tests should be deterministic and not rely on external services

## Documentation

### Updating the README

When making changes that affect usage:

- Update code examples
- Add new features to the Features section
- Update configuration options if changed
- Add troubleshooting tips for common issues

### API Documentation

- Use Swift's documentation markup
- Include code examples for complex APIs
- Document all parameters, return values, and thrown errors
- Keep documentation in sync with implementation

## Release Process

Releases are managed by maintainers. The process includes:

1. Update CHANGELOG.md with new version
2. Update version references in documentation
3. Create a git tag with version number
4. Push tag to trigger release workflow
5. Create GitHub release with release notes

## Questions?

If you have questions about contributing:

- Open a [GitHub Discussion](https://github.com/YOUR-USERNAME/VaporHealthCheck/discussions)
- Review existing issues and pull requests
- Check the README for basic usage questions

Thank you for contributing to VaporHealthCheck! 🎉
