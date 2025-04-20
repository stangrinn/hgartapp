# ARKitVideoOverlay

ARKitVideoOverlay is an iOS application that uses augmented reality to overlay videos on real-world objects. The app recognizes predefined image targets and plays corresponding videos on top of them, creating an immersive AR experience.

## Features

- **Image Recognition**: Detects predefined target images from a configuration file
- **Video Overlay**: Places and plays videos directly on top of recognized targets
- **Real-time Tracking**: Videos follow the tracked images as they move in 3D space
- **UI Controls**: Toggle mute/unmute for video playback
- **Target Scanner**: Visual guide to help users find and scan targets

## Architecture

The application follows a modular architecture with specialized managers for different responsibilities:

- **ARSessionManager**: Handles AR session configuration, image target loading, and tracking setup
- **ARSceneManager**: Manages AR scene elements, node creation, and scene graph updates
- **VideoManager**: Controls video playback, state management, and player controls
- **VideoOverlayManager**: Creates and manages video overlays on detected targets
- **RecordingManager**: Handles screen recording functionality
- **PlayerObserver**: Observes player state changes using KVO

## Technical Details

- **Frameworks**: ARKit, SceneKit, AVFoundation, SpriteKit, ReplayKit
- **Minimum iOS Version**: 15.0
- **Target Devices**: iPhone and iPad
- **Swift Version**: 5.5+

## Setup and Configuration

### Target Configuration

The app loads targets from a remote JSON configuration:

```json
{
  "targets": [
    {
      "name": "target1",
      "imageUrl": "https://example.com/target1.jpg",
      "videoUrl": "https://example.com/video1.mp4",
      "physicalWidth": 0.1
    }
  ]
}
```

Each target has:
- A unique name
- URL to the reference image
- URL to the video that will be played when the target is recognized
- Physical width in meters of the reference image

### Usage

1. Point the device camera at a recognized target image
2. The app will display a scanning overlay to help with alignment
3. Once recognized, the video will play directly on top of the target
4. Use on-screen controls to manage playback

## Project Structure

```
ARKitVideoOverlay/
├── Managers/
│   ├── ARSceneManager.swift
│   ├── ARSessionManager.swift
│   ├── RecordingManager.swift
│   ├── VideoManager.swift
│   └── VideoOverlayManager.swift
├── Helpers/
│   ├── PlayerObserver.swift
│   └── TargetScannerOverlay.swift
├── Models/
│   └── ARTarget.swift
├── UI/
│   ├── Assets/
│   │   └── Loader.mp4
│   └── Components/
│       └── ToggledIconButton.swift
└── ViewController.swift
```

## Testing

The project includes comprehensive unit tests for all major components. Tests are organized to mirror the structure of the main application:

```
ARKitVideoOverlayTests/
├── Managers/
│   ├── ARSceneManagerTests.swift
│   ├── ARSessionManagerTests.swift
│   ├── VideoManagerTests.swift
│   └── VideoOverlayManagerTests.swift
├── Helpers/
│   ├── PlayerObserverTests.swift
│   └── TargetScannerOverlayTests.swift
└── UI/
    └── Components/
        └── ToggleIconButtonTests.swift
```

## Requirements

- Xcode 14.0+
- iOS 15.0+
- Swift 5.5+
- Device with ARKit support

## License

Copyright © 2025 weARt. All rights reserved. 