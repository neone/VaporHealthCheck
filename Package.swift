// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "VaporHealthCheck",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "VaporHealthCheck",
            targets: ["VaporHealthCheck"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.28.0")
    ],
    targets: [
        .target(
            name: "VaporHealthCheck",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "SQLKit", package: "sql-kit")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaporHealthCheckTests",
            dependencies: [
                .target(name: "VaporHealthCheck"),
                .product(name: "XCTVapor", package: "vapor")
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableExperimentalFeature("StrictConcurrency")
] }