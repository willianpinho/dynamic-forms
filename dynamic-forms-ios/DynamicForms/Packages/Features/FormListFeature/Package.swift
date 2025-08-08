// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FormListFeature",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FormListFeature",
            targets: ["FormListFeature"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/UIComponents"),
        .package(path: "../../Core/Utilities"),
        .package(path: "../../Data/DataRepository"),
    ],
    targets: [
        .target(
            name: "FormListFeature",
            dependencies: [
                "Domain",
                "DesignSystem",
                "UIComponents",
                "Utilities",
                "DataRepository"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "FormListFeatureTests",
            dependencies: ["FormListFeature"],
            path: "Tests"
        ),
    ]
)