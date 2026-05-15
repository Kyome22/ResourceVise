# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

ResourceVise is a sandboxed macOS app (deployment target 14.6, Swift 6.0, bundle id `com.kyome.vise.resource`) that converts image files to WebP and compresses them. The `.xcodeproj` is a thin host: the real code lives in `LocalPackage`, a local Swift Package with three library targets (`DataSource`, `Model`, `UserInterface`) plus a `ModelTests` test target. The app entry point (`ResourceVise/ResourceViseApp.swift`) only wires `AppDelegate` and `ImageViseWindowScene` from those modules.

## Build, test, run

- Prefer Xcode MCP Tools if available; otherwise use the commands below.
- Build the app: `xcodebuild -project ResourceVise.xcodeproj -scheme ResourceVise -configuration Debug build`
- Build/test the package (no app shell needed for logic work): `cd LocalPackage && swift build` / `swift test`
- Run a single test: `cd LocalPackage && swift test --filter ModelTests.<TestName>`
- External SPM deps are pinned in `LocalPackage/Package.swift` (`swift-log` 1.12.0, `WebPEncoder` 0.1.1). Both `ExistentialAny` upcoming feature is enabled across targets.

## Architecture

Three layers, strictly one-way dependency: `UserInterface → Model → DataSource`. Do not import upward, and do not import `AppKit`/`SwiftUI` from `DataSource`.

### DataSource layer (`LocalPackage/Sources/DataSource`)
- `DependencyClient` protocol (`DependencyClient.swift`) — every external boundary is a `struct` with closure properties and provides `static let liveValue` (production) and `static let testValue` (no-op default). Use the `testDependency(of:injection:)` helper to override only the closures you care about in tests.
- `Dependencies/*Client.swift` — thin wrappers around `FileManager`, `NSWorkspace`, `NSImage`, `URL` bookmark APIs, `UserDefaults`, `Data` I/O, `LoggingSystem`, and the in-memory `AppStateClient`. `AppStateClient` owns an `OSAllocatedUnfairLock<AppState>` and exposes `withLock { ... }`; it holds `homeDirectory` and a `PassthroughSubject<Double, Never>` (`progressSubject`) that Model streams progress through.
- `Repositories/*` — compose multiple clients into a domain operation (e.g. `BookmarkRepository` combines `URLClient` + `UserDefaultsClient` for security-scoped home-directory bookmarks).
- `Entities/*` — plain `Sendable` value types (`AppState`, `BookmarkState`, `ImageFile`) and event enums under `Entities/Events/` (`NoticeEvent`, `ErrorEvent`, `CriticalEvent`) that carry typed `message`/`metadata` payloads for `LogService`.

### Model layer (`LocalPackage/Sources/Model`)
- `AppDependencies` (`AppDependencies.swift`) is the single composition root: a `Sendable` struct of every `*Client`, with a shared `liveValue` instance and `testDependencies(...)` factory. It is exposed to SwiftUI via `EnvironmentValues.appDependencies` (`@Entry`). Inject the whole `AppDependencies` into stores/services — do not pass individual clients from views.
- `Composable` protocol (`Composable.swift`) — every store conforms. Pattern: `@MainActor @Observable final class`, holds dependencies + repositories + services as `private let`, exposes observed `var` state, plus `let action: (Action) async -> Void` callback for parent stores. The protocol provides `send(_:)` which calls `reduce(_:)` then forwards to `action`. Define a nested `enum Action: Sendable` per store.
- Stores (`Stores/`) — `ImageVise` is the root store (drives `ImageViseView`); `HomePermission` is presented as a sheet and reports back to `ImageVise` via its `action` callback (see `ImageVise.reduce` → `.homePermission(...)` cases).
- Services (`Services/`) — stateless `struct`s constructed from `AppDependencies`. `ImageConvertService` orchestrates WebP encoding (`WebPEncoder`, quality 0.9, `.picture` preset), file replacement, and progress emission through `appStateClient.progressSubject`. `LogService` bootstraps `swift-log` (stdout in DEBUG only, once-per-process guarded via `AppState.hasAlreadyBootstrap`) and offers `nonisolated notice/error/critical` taking the typed event enums.
- `AppDelegate` runs at launch: `LogService.bootstrap()` → log launch → `ImageConvertService.setHomeDirectory()`. On terminate it releases the security-scoped bookmark.
- `ImageViseActionWrapper` is the `Sendable` adapter used to expose `ImageVise.send` through SwiftUI `@FocusedValue` so the menu-bar `CommandGroup` in `ImageViseWindowScene` can dispatch actions into the focused window's store.

### UserInterface layer (`LocalPackage/Sources/UserInterface`)
- Views read `@Environment(\.appDependencies)` and instantiate stores with it (`ImageViseView` uses `@StateObject var store: ImageVise`; `ImageVise` is extended to `ObservableObject` inside the view file so SwiftUI can hold it).
- View → store communication is exclusively `await store.send(.someAction)` inside `Task { ... }`. There is no direct state mutation from views beyond `$store.foo` two-way bindings on `@Observable` properties.
- Lifecycle: each top-level view sends `.task(appDependencies, String(describing: Self.self))` from `.task { }` and `.onDisappear` for cleanup. The screen name string is logged via `LogService.notice(.screenView(name:))`.
- Localized strings live in `Resources/Localizable.xcstrings` and are referenced with `Text("key", bundle: .module)`; image assets are in `Resources/Media.xcassets`.

### Conventions to follow when adding code
- New external API → add a `*Client: DependencyClient` in `DataSource/Dependencies/`, then a property on `AppDependencies` (both the default and `testDependencies(...)`).
- New screen → store in `Model/Stores/` conforming to `Composable` with a nested `Action` enum; view in `UserInterface/Views/` (or `Scenes/` for a `Scene`); strings into `Localizable.xcstrings`.
- Logging → add a typed event case under `DataSource/Entities/Events/` and call `LogService.notice/error/critical(...)`; do not use `print` for production paths.
- Progress → write to `appStateClient.withLock { $0.progressSubject.send(value) }` and consume via `appStateClient.withLock(\.progressSubject.values)` in a `Task` inside the store.
- Sandbox: entitlements grant only `user-selected.read-write` + `network.client`. Anything outside user-selected files requires a security-scoped bookmark via `BookmarkRepository`.

## Tests

Tests live in `LocalPackage/Tests/ModelTests/` and use the `Testing` framework (`@Test`, `#expect`). The default test seam is `AppDependencies.testDependencies(...)` plus `testDependency(of: SomeClient.self) { $0.someClosure = ... }` to stub specific calls. The current `ModelTests.swift` is a placeholder.
