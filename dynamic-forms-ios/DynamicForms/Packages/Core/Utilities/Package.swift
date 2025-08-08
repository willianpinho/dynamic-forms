// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Utilities",
            targets: ["Utilities"]
        ),
    ],
    dependencies: [
        // No external dependencies for Utilities
    ],
    targets: [
        .target(
            name: "Utilities",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "UtilitiesTests",
            dependencies: ["Utilities"],
            path: "Tests"
        ),
    ]
)