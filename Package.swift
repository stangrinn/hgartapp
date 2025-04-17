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
            linkerSettings: [
                .linkedFramework("ARKit"),
                .linkedFramework("SceneKit"),
                .linkedFramework("UIKit"),
                .linkedFramework("AVFoundation")
            ]
        )
    ]
)
