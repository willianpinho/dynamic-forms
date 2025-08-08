// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FormEntriesFeature",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FormEntriesFeature",
            targets: ["FormEntriesFeature"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/UIComponents"),
        .package(path: "../../Core/Utilities"),
    ],
    targets: [
        .target(
            name: "FormEntriesFeature",
            dependencies: [
                "Domain",
                "DesignSystem",
                "UIComponents",
                "Utilities"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "FormEntriesFeatureTests",
            dependencies: ["FormEntriesFeature"],
            path: "Tests"
        ),
    ]
)