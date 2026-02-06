// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-tql",
    platforms: [
        .macOS(.v13),
        .iOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftTQL",
            targets: ["SwiftTQL"]
        ),
        .library(
            name: "SwiftDruid",
            targets: ["SwiftDruid"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(name: "SwiftDateOperations", path: "../SwiftDateOperations"), // local development
        .package(url: "https://github.com/TelemetryDeck/SwiftDateOperations.git", from: "2.0.1"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.8.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftTQL",
            dependencies: [
                .product(name: "DateOperations", package: "SwiftDateOperations"),
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
        .target(
            name: "SwiftDruid",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "QueryTests",
            dependencies: ["SwiftTQL"]
        ),
        .testTarget(
            name: "QueryResultTests",
            dependencies: ["SwiftTQL"]
        ),
        .testTarget(
            name: "QueryGenerationTests",
            dependencies: ["SwiftTQL"]
        ),
        .testTarget(
            name: "SupervisorTests",
            dependencies: ["SwiftTQL"]
        ),
        .testTarget(
            name: "DataSchemaTests",
            dependencies: ["SwiftTQL"]
        ),
    ]
)
