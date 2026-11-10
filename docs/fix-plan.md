# Fix plan — branch `fix/develop-fixes` (from `develop`)

Status legend: `[ ]` open, `[~]` in progress, `[x]` done, `[?]` waiting for approval.

## P1 — reliability

- [x] **1. Data race in `ARSceneCoreManager`.** `referenceImages` (a `Set`) is mutated from concurrent `URLSession` callbacks. Collect results on one serial queue (or async/await `TaskGroup`).
- [x] **2. Silent failures.** Missing `ar-config.json`, zero loaded targets or a network error must still call `completion` and surface a user-visible state instead of leaving the session unstarted.
- [x] **3. Stale image cache.** Decided: cache keyed by SHA-256 of the image URL (no `revision` field); the cache is now actually written, and files for URLs no longer in the config are purged. Cache key is only the target name; an updated image with the same name is never re-downloaded. Key the cache by the target `revision` from the contract (see below).

## P2 — quality

- [?] **4. Target contract.** See the proposal below; blocks items 2 and 3.
- [ ] **5. Preloader selection.** `AppEnvironment.preloaderResourceName` always returns `Loader-kids`; restore environment-based choice or drop the dead branch.
- [x] **6. Camera permission duplicated** in `viewDidAppear` and `setupManagers`; keep one path.
- [~] **7. Dead code and noise.** Done in `ARSceneCoreManager`/`ViewController` (`6bf9213`, `6e37e44`); failure `print`s kept until item 2 replaces them with an error state. Also found: the image cache is read but never written, so it is always empty (handled in item 3). Remove `noCacheSession`, `nonCachingRequest` and debug `print` calls.

## P3 — hygiene

- [ ] **8. `MARKETING_VERSION`** mismatch (1.0 vs 1.6) in `project.pbxproj`.
- [ ] **9. README** is stale (removed managers, iOS 15 vs deployment target 18.2).
- [ ] **10. Tests** for target loading (mock session) and `AppEnvironment`.
- [x] **11. Video delivery as a stream.** Option A chosen: `fix/ar-video-loading` fast-forwarded into this branch (streaming, 12 tarot targets in `ar-config.json`). Kids targets are deferred; later, add every AR-enabled work from the site once streaming is confirmed on device.

Coordinate with `fix/ar-video-loading` (video streaming changes) before touching video code.

---

## Change contract — what will change and how (for approval)

Branch work happens directly in the main working copy on `fix/develop-fixes`; one commit per item.

| # | Files touched | Change | Behaviour impact |
|---|---|---|---|
| 1 | `Managers/ARSceneCoreManager.swift` | Download targets concurrently but write `referenceImages` only on a private serial queue (results gathered, then applied in `group.notify`). | None visible; removes the data race. |
| 2 | `ARSceneCoreManager.swift`, `ViewController.swift` | `loadTargetsAndStartARSession` always calls `completion`; on missing config, or no valid target, it reports an error and `ViewController` shows a simple message state. Failed individual targets are skipped as today. | New error UI for previously silent cases. |
| 3 | `ARSceneCoreManager.swift` | Cached file name becomes `<name>-<revision>.jpg` (revision from config; absent = current name); stale files of the same target are removed. Needs the data-format decision below. | One-time re-download after update. |
| 5 | `Helpers/AppEnvironment.swift` | `preloaderResourceName` returns `Loader-kids` only for the App Clip, `Loader` otherwise, if the `Loader` asset still exists; otherwise drop the dead branch. | Possibly different preloader in the main app. |
| 6 | `ViewController.swift` | Single `handleCameraAuthorization()` used by `viewDidAppear` and `setupManagers`. | None. |
| 7 | `ARSceneCoreManager.swift`, `ViewController.swift` | Delete `noCacheSession`, `nonCachingRequest` and debug `print` calls. | None. |
| 8 | `HGArt.xcodeproj/project.pbxproj` | Set the two `MARKETING_VERSION = 1.0` entries to 1.6 (will check which targets they belong to first). | Build setting only. |
| 9 | `README.md` | Rewrite structure/architecture to match the code; minimum iOS 18.2. | Docs only. |
| 10 | `Tests/**` | Add tests for config decoding and `AppEnvironment`; no refactor for testability beyond an injectable `URLSession`. | Tests only. |

Not changed: networking endpoints, `ar-config.json` content, app clip entitlements, video playback code (owned by `fix/ar-video-loading`), bundle identifiers.

## Decision: streaming video (item 11)

Today `develop` downloads the whole MP4 into `Caches/ARVideos/<file>` (`cachedURL`) before playback, so the user waits on the preloader for the full file. Branch `fix/ar-video-loading` (2 commits, not in `develop`) already implements direct streaming: `AVPlayerItem(asset: AVURLAsset(https))` with `preferredForwardBufferDuration = 3`, buffering/error panel from `PlayerObserver`, `suspendStreams()` when the app is inactive, tracking-loss fix, HTTPS-only validation and updated tests. It also touches `ARSceneManager`, `ViewController`, `PlayerObserver`, `ar-config.json` and README, so it overlaps items 2, 6, 7 and 9.

Options:

- **A (recommended): bring in those 2 commits** (merge into `fix/develop-fixes` before items 2/6/7), then do our items on top. Progressive MP4 over HTTPS; no local video cache, so every start and every loop depends on the network. Server requirement: HTTP `Range` support and `moov` atom at the file start (`ffmpeg -movflags +faststart`); the videos live on `helenagrinshpun.art/wp-content/...`, which must be verified.
- **B: stream plus background cache.** Play from the URL immediately and copy the file into `Caches` for the next launch (via a parallel download or an `AVAssetResourceLoader`). Better offline/repeat experience, noticeably more code and edge cases (partial files, eviction).
- **C: HLS.** Adaptive streaming and `AVAssetDownloadURLSession` offline support, but needs server-side transcoding and a change of `videoUrl` format.

Verification (2026-11-09, read-only HTTP checks):

- All 10 targets in `develop`'s `ar-config.json` (`/wp-content/uploads/...` on the old WordPress site) return **404** for both image and video, so AR is currently broken on `develop`.
- The config from `fix/ar-video-loading` has 12 tarot targets on the new platform (`/assets/preview/...` image, `/assets/source/...` video): every image returns 200, every video supports `Range` (206, `Accept-Ranges: bytes`) and has `moov` before `mdat` (faststart), so progressive streaming works. That file is now applied on this branch (staged, not committed).
- The public Shop API lists 34 products but exposes no video assets, so the 10 kids targets (Alphabet, Alphabet Hebrew, Numbers, Brave, Morning, Evening, Creative, Happy birthday x2, Shapes) are **dropped** from the config until their new video URLs are provided. Other tarot/"Woman of ..." products have no AR video in the public API either; Admin API was not queried.

Proposed contract for A: no changes to the streaming code itself beyond conflict resolution; additionally verify `Accept-Ranges` and faststart for all 10 videos (read-only `curl -I` checks) and record the result here.

## Appendix: target data format (needed for items 2 and 3)

### Current format (v1, implicit)

```json
{ "targets": [ { "name": "", "imageUrl": "", "videoUrl": "", "physicalWidth": 0.42 } ] }
```

Bundled in `Resources/ar-config.json`; every catalog change needs an app release. `name` doubles as identity and cache key.

### Proposed format (v2, backward compatible)

```json
{
  "schemaVersion": 2,
  "targets": [
    {
      "id": "alphabet-kids",
      "name": "Alphabet",
      "imageUrl": "https://helenagrinshpun.art/.../Alphabet-kids.png",
      "videoUrl": "https://helenagrinshpun.art/.../Alphabet-kids1.mp4",
      "physicalWidth": 0.42,
      "revision": "2025-10-12",
      "enabled": true
    }
  ]
}
```

Fields:

| Field | Required | Meaning |
|---|---|---|
| `schemaVersion` | no (absent = 1) | Contract version; the app rejects versions higher than it knows and falls back. |
| `id` | v2 yes (v1: falls back to `name`) | Stable identity and ARKit reference-image name; never changes. |
| `name` | yes | Display name only. |
| `imageUrl`, `videoUrl` | yes | HTTPS URLs. |
| `physicalWidth` | yes | Printed image width in metres, `> 0`. |
| `revision` | no | Opaque string; a change invalidates the cached image. Absent = never invalidated. |
| `enabled` | no (default `true`) | Lets the catalog hide a target without an app release. |

Rules:

- Unknown fields are ignored; an invalid target (bad URL, non-HTTPS, `physicalWidth <= 0`, duplicate `id`) is skipped and logged, it never fails the whole config.
- Decoding stays tolerant of v1 files, so the bundled config keeps working unchanged.
- The result is at least a loaded subset; zero valid targets is an explicit error state (item 2).

### Delivery (decision needed)

- **A (recommended):** bundled config stays the fallback; the app additionally fetches `https://helenagrinshpun.art/ar-config.json` (URL not final), stores the last good copy in `Caches`, and uses it on the next launch. Order: remote (fresh) → last good cache → bundled.
- **B:** bundled only (current behaviour), with the v2 fields. No server work, still needs a release per catalog change.

Open questions: final remote URL and who publishes the file; whether `id` values can be derived from existing names for the current 10 targets.
