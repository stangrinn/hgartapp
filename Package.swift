// swift-tools-version:5.5
import PackageDescription

let package: Package = Package(
    name: "ARKitVideoOverlay",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "ARKitVideoOverlay",
            targets: ["ARKitVideoOverlay"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ARKitVideoOverlay",
            dependencies: [],
            path: "ARKitVideoOverlay",
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
            name: "ARKitVideoOverlayTests",
            dependencies: ["ARKitVideoOverlay"],
            path: "ARKitVideoOverlayTests"
        )
    ]
)
