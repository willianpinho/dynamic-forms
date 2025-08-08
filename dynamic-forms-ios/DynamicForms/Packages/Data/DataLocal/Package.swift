// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DataLocal",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DataLocal",
            targets: ["DataLocal"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Core/Utilities"),
    ],
    targets: [
        .target(
            name: "DataLocal",
            dependencies: [
                "Domain",
                "Utilities"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "DataLocalTests",
            dependencies: ["DataLocal"],
            path: "Tests"
        ),
    ]
)