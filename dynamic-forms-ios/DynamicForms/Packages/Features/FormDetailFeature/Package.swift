// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FormDetailFeature",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FormDetailFeature",
            targets: ["FormDetailFeature"]
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
            name: "FormDetailFeature",
            dependencies: [
                "Domain",
                "DesignSystem",
                "UIComponents",
                "Utilities"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "FormDetailFeatureTests",
            dependencies: ["FormDetailFeature"],
            path: "Tests"
        ),
    ]
)