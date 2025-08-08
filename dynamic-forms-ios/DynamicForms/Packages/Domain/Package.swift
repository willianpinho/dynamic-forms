// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Domain",
            targets: ["Domain"]
        ),
    ],
    dependencies: [
        .package(path: "../Core/Utilities"),
    ],
    targets: [
        .target(
            name: "Domain",
            dependencies: [
                "Utilities"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"],
            path: "Tests"
        ),
    ]
)