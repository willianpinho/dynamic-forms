// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DataMapper",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DataMapper",
            targets: ["DataMapper"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Core/Utilities"),
    ],
    targets: [
        .target(
            name: "DataMapper",
            dependencies: [
                "Domain",
                "Utilities"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "DataMapperTests",
            dependencies: ["DataMapper"],
            path: "Tests"
        ),
    ]
)