// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DesignSystem",
            targets: ["DesignSystem"]
        ),
    ],
    dependencies: [
        // No external dependencies for DesignSystem
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            path: "Tests"
        ),
    ]
)