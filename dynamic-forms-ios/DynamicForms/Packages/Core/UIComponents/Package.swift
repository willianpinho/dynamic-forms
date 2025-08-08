// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UIComponents",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "UIComponents",
            targets: ["UIComponents"]
        ),
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../Utilities"),
    ],
    targets: [
        .target(
            name: "UIComponents",
            dependencies: [
                "DesignSystem",
                "Utilities"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "UIComponentsTests",
            dependencies: ["UIComponents"],
            path: "Tests"
        ),
    ]
)