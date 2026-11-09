# HGARt Architecture Boundaries

## Goal
Define strict module boundaries before migrating runtime logic.

## Target Layers

### Presentation
- Coordinates user flow and screen state.
- Knows UIKit/SwiftUI, but does not perform networking, caching, or AR/data orchestration directly.
- Entry points:
  - `AppCompositionRoot`
  - `ARExperienceCoordinator`
  - `ARExperienceViewModel`
  - `ARExperienceViewController`

### Domain
- Pure app rules and use-cases.
- Depends only on models and protocol contracts (ports).
- No UIKit/ARKit/AVFoundation and no direct I/O.

### Data
- Implements Domain ports and works with persistence/network.
- Converts raw payloads (`ar-config.json`, remote URLs) into domain models.
- Owns caching policy decisions.

### Infrastructure
- Thin adapters around frameworks:
  - ARKit/SceneKit session and scene delegates
  - AVFoundation players
  - URLSession, FileManager

## Dependency Rules
Allowed directions only:

1. `Presentation -> Domain`
2. `Data -> Domain`
3. `Infrastructure -> Data` (optional adapter composition)

Disallowed:

1. `Domain -> Presentation`
2. `Domain -> Data`
3. `Presentation -> Infrastructure` (except via composed interfaces)
4. Cross-calls between unrelated managers without protocol boundary

## Transitional Mapping (Current -> Target)

1. `ViewController` -> stays temporary shell, moves orchestration to `ARExperienceCoordinator + ViewModel`.
2. `ARSceneCoreManager` -> split into:
   - `TargetsRepository` (Data)
   - `ARSessionService` (Infrastructure)
3. `ARSceneVideoOverlay` -> split into:
   - `VideoCacheService` (Data)
   - `VideoPlaybackService` (Infrastructure)
4. `ARSceneManager` -> ARKit adapter (Infrastructure) + callbacks to Presentation/Domain.

## Definition of Done for Boundary Phase

1. Root controller creation goes through `AppCompositionRoot`.
2. Domain protocol ports exist for target loading, session lifecycle, and video caching.
3. New feature code is added to `Presentation/Domain/Data/Infrastructure` folders first.
4. Runtime behavior remains unchanged.
