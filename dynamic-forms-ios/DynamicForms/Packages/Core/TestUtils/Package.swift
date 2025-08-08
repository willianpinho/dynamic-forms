// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TestUtils",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "TestUtils",
            targets: ["TestUtils"]
        ),
    ],
    dependencies: [
        .package(path: "../Utilities"),
    ],
    targets: [
        .target(
            name: "TestUtils",
            dependencies: [
                "Utilities"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "TestUtilsTests",
            dependencies: ["TestUtils"],
            path: "Tests"
        ),
    ]
)