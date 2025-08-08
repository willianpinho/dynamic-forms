// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DataRepository",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DataRepository",
            targets: ["DataRepository"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../DataLocal"),
        .package(path: "../DataMapper"),
        .package(path: "../../Core/Utilities"),
    ],
    targets: [
        .target(
            name: "DataRepository",
            dependencies: [
                "Domain",
                "DataLocal",
                "DataMapper",
                "Utilities"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "DataRepositoryTests",
            dependencies: ["DataRepository"],
            path: "Tests"
        ),
    ]
)