// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftTQL",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftTQL",
            targets: ["SwiftTQL"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/TelemetryDeck/SwiftDateOperations.git", from: "1.0.5"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.8.0"),
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
