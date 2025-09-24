// swift-tools-version:5.5
import PackageDescription

let package: Package = Package(
    name: "HGARt",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "HGARtApp",
            targets: ["HGARtApp"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HGARtApp",
            dependencies: [],
            path: "HGARtApp",
            resources: [
                .process("UI/Assets/Loader.mp4"),
                .process("Assets.xcassets")
            ],
            linkerSettings: [
                .linkedFramework("ARKit"),
                .linkedFramework("SceneKit"),
                .linkedFramework("UIKit"),
                .linkedFramework("AVFoundation")
            ]
        ),
        .testTarget(
            name: "HGARtTests",
            dependencies: ["HGARtApp"],
            path: "Tests"
        )
    ]
)
