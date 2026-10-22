# Current Architecture Reference

> Flutter Starter Template — Verified Architecture Snapshot
> Branch: `feat/foundation-certification` | Last verified: 2026-10-22
> All file paths, class names, and relationships verified against actual code.

---

## 1. Repository Layout

```
flutter-starter-template/
├── lib/                          # Application shell (host app)
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart              # MaterialApp root
│   │   ├── features.dart         # Feature registry + FeatureModule declarations
│   │   ├── router.dart           # GoRouter composition (TypedStatefulShellRoute)
│   │   ├── firebase.dart         # kFirebaseEnabled compile-time flag
│   │   ├── di/
│   │   │   ├── injection.dart    # @InjectableInit + externalPackageModulesBefore
│   │   │   ├── injection.config.dart  # GENERATED — do not edit
│   │   │   └── reader_fallbacks.dart  # Null-object fallbacks for excluded features
│   │   └── widgets/
│   │       └── app_shell.dart    # StatefulShellRoute scaffold (bottom nav)
│   └── core/
│       └── data/
│           └── database/
│               ├── object_box_module.dart   # @module for ObjectBox (default)
│               └── drift_module.dart        # @module for Drift (--database drift)
├── packages/
│   ├── architecture/             # Core contracts: Result, Failure, UseCase
│   ├── app_ui/                   # Design system: tokens, widgets, SemanticColors
│   ├── localization/             # i18n (ARB → generated l10n classes)
│   ├── theme/                    # ThemeData composition
│   ├── shared_ui/                # Cross-feature presentation scopes
│   ├── shared_contracts/         # Narrow cross-feature state interfaces (ActivityNotifier, etc.)
│   ├── analytics/                # AnalyticsService port + Firebase adapter
│   ├── config/                   # Remote Config (Firebase or local)
│   ├── network/                  # Dio + Retrofit HTTP infrastructure
│   ├── storage/                  # AuthTokenStore + FlutterSecureStorage
│   ├── app_platform/             # Platform detection utilities
│   ├── sync_connectivity_plus/   # Connectivity adapter for sync engine
│   ├── database/                 # ObjectBox (default) — committed binding
│   ├── database_drift/           # Drift template — renamed to `database` by CLI
│   ├── document_engine/          # Document format engine (optional)
│   ├── test_utils/               # Shared fakes, fixtures (dev_dependency only)
│   └── features/
│       ├── auth/                 # Authentication (optional pillar)
│       ├── bookmarks/            # Bookmarks feature
│       ├── collections/          # Collections feature
│       ├── notifications/        # Notifications feature
│       ├── home/                 # Always-present home tab
│       ├── splash/               # Always-present splash screen
│       ├── profile/              # Always-present profile tab
│       └── document_center/      # Document Center (optional)
├── published/
│   ├── cli/                      # fst CLI submodule (Hosamalbushri fork)
│   └── rev_sync/                 # Offline-first sync engine submodule
├── test/
│   └── architecture/             # Architecture guardrail tests (18 files)
├── tool/
│   ├── setup.sh                  # One-shot bootstrap (idempotent)
│   ├── codegen.sh                # build_runner across workspace
│   └── test_objectbox.sh         # ObjectBox-specific test runner
├── .github/
│   └── workflows/
│       ├── ci.yml                # Main CI (30 jobs)
│       └── release.yml           # App Store / Play Store deploy
├── CLAUDE.md                     # AI agent guidance (verified present)
└── .fvmrc                        # Flutter version pin (currently 3.44.0)
```

---

## 2. Package Categories and Layer Ranks

Defined in [`test/architecture/package_layering_test.dart`](../../test/architecture/package_layering_test.dart).

| Layer | Rank | Packages |
|-------|------|----------|
| Foundation | 0 | `architecture`, `rev_sync` |
| Platform Contracts | 1 | `app_platform`, `sync_connectivity_plus` |
| Infrastructure | 2 | `analytics`, `config`, `database`, `database_drift`, `network`, `storage`, `document_engine` |
| Contracts + UI | 3 | `shared_contracts`, `app_ui`, `localization`, `theme`, `shared_ui`, `test_utils` |
| Features | 4 | All `feature_*` packages |
| Application Shell | 5 | Root `lib/` (not a package — no other package may depend on it) |

### Dependency Direction Rule
A package may only depend on packages with a **strictly smaller layer rank**.
Cycles are detected by DFS in `detectDependencyCycles()`.

### Category Dependency Allowlist
```
applicationShell → feature, sharedDomainContracts, uiDesignSystem, infrastructureService, platformIntegration
feature          → feature (within allowlist), sharedDomainContracts, uiDesignSystem, infrastructureService, platformIntegration
sharedDomainContracts → sharedDomainContracts only
uiDesignSystem   → uiDesignSystem, sharedDomainContracts, infrastructureService
infrastructureService → infrastructureService, sharedDomainContracts
platformIntegration → platformIntegration, infrastructureService, sharedDomainContracts
devTestUtilities → sharedDomainContracts, uiDesignSystem, infrastructureService, platformIntegration
```

---

## 3. Domain Contracts (package: architecture)

Located in `packages/architecture/lib/src/`.

### `Result<T>` — `result.dart`
```dart
sealed class Result<T> { const Result(); }
final class Ok<T> extends Result<T> { const Ok(this.value); final T value; }
final class Err<T> extends Result<T> { const Err(this.failure); final Failure failure; }
```
Use exhaustive pattern matching at call sites. No `null` sentinels.

### `Failure` — `failure.dart`
```dart
sealed class Failure { const Failure(this.message); final String message; }
```
Subclasses (all verified in `failure.dart`):
- `UnknownFailure` — catch-all
- `NoSessionFailure` — expected absence of persisted session
- `InvalidCredentialsFailure`
- `NotFoundFailure`
- `ValidationFailure`
- `PermissionFailure` / `CameraPermissionFailure`
- `MediaPickFailure`

### `UseCase<Param, Output>` — `use_case.dart`
```dart
abstract class UseCase<Param, Output> {
  Future<Result<Output>> call(Param param);
  Future<Result<Output>> runGuarded(FutureOr<Output> Function() op, {FailureMapper? mapFailure});
  Future<Result<Output>> runResultGuarded(FutureOr<Result<Output>> Function() op, {FailureMapper? mapFailure});
}
abstract class NoParamUseCase<Output> extends UseCase<NoParams, Output> {}
```

---

## 4. Dependency Injection Architecture

### Pattern Overview

The DI system uses `get_it` + `injectable` + `injectable_generator`.

**App-root orchestration** (`lib/app/di/injection.dart`):
```dart
@InjectableInit(
  externalPackageModulesBefore: [
    ExternalModule(AnalyticsPackageModule),
    ExternalModule(ConfigPackageModule),
    ExternalModule(StoragePackageModule),      // ← must precede NetworkPackageModule
    ExternalModule(NetworkPackageModule),
    ExternalModule(AppPlatformPackageModule),
    ExternalModule(ThemePackageModule),
    ExternalModule(SyncConnectivityPlusPackageModule),
    ExternalModule(SharedContractsPackageModule), // ← must precede FeatureNotificationsPackageModule
    ExternalModule(FeatureAuthPackageModule),
    ExternalModule(FeatureNotificationsPackageModule),
    ExternalModule(FeatureCollectionsPackageModule),
    ExternalModule(FeatureBookmarksPackageModule),
    ExternalModule(FeatureHomePackageModule),
    ExternalModule(FeatureProfilePackageModule),
    // ... fst markers for optional features
  ],
)
Future<void> configureDependencies() async { ... }
```

**Load-bearing ordering constraints** (enforced by `di_module_ordering_test.dart`):
1. `StoragePackageModule` before `NetworkPackageModule` — Network needs `AuthTokenStore`.
2. `SharedContractsPackageModule` before `FeatureNotificationsPackageModule` — Notifications BLoC resolves `ActivityNotifier` at construction.

### Micro-Package Self-Registration

Each feature package has:
- `lib/src/di.dart` — internal DI configuration (NOT exported by barrel)
- `lib/src/di.module.dart` — GENERATED module class (exported by barrel)

Example from `feature_bookmarks`:
```dart
// In lib/src/data/local/bookmarks_local_data_source.dart
@LazySingleton(as: BookmarksLocalDataSource)
class ObjectBoxBookmarksDataSource implements BookmarksLocalDataSource { ... }
```

The feature registers its own data sources. The app-root DI module (`DriftModule` or `ObjectBoxModule`) provides only engine primitives:
- `AppDatabase` (Drift) or `Store` (ObjectBox)
- `AtomicWriteCoordinator`
- `SyncCursorStore`

### Firebase Runtime Bindings
`configureFirebaseRuntimeBindings(getIt)` replaces Firebase-backed adapters with no-op implementations when `kFirebaseEnabled` is `false`. Verified by `firebase_optional_di_test.dart`.

### Reader Fallbacks
`registerReaderFallbacks(getIt)` provides `NoOpBookmarkStatsReader` and `NoOpCollectionsReader` when optional features are excluded, keeping `home` functional. Idempotent — safe to call multiple times.

---

## 5. Feature Marker System

Files use `// fst:feature:xxx:start` … `// fst:feature:xxx:end` marker pairs. The CLI strips entire regions when a feature is excluded.

### Defined Markers
| Marker | Controls |
|--------|---------|
| `fst:feature:bookmarks` | Bookmarks feature code |
| `fst:feature:collections` | Collections feature code |
| `fst:feature:notifications` | Notifications feature code |
| `fst:auth` | Authentication pillar |
| `fst:network` | Network package |
| `fst:backend` | Backend infrastructure |
| `fst:feature:_router` | `go_router` import (always preserved when routes remain) |
| `fst:feature:_infra` | App-internal infrastructure (non-backend) |
| `fst:document:engine` | Document Engine package |
| `fst:document:center` | Document Center feature |
| `fst:db:objectbox` | ObjectBox-only code blocks |
| `fst:db:drift` | Drift-only code blocks |
| `fst:template-only` | CI/tooling blocks stripped from scaffolds |

### Rule: Marker Containment
Each feature's code must be entirely within its own marker block. Cross-nesting (e.g. document_center inside notifications markers) is a bug caught by `foundation_phase02_regression_test.dart`.

---

## 6. Routing Architecture

`lib/app/router.dart` composes a `TypedStatefulShellRoute` with `go_router`. The shell has fixed branches (Home, Profile) plus optional feature branches wrapped in markers.

```
AppShellRouteData (StatefulShellRoute)
├── HomeBranchData → HomeRoute (path: '/')
├── BookmarksBranchData (fst:feature:bookmarks) → BookmarksListRoute (path: '/bookmarks')
├── NotificationsBranchData (fst:feature:notifications) → NotificationsRoute (path: '/notifications')
└── ProfileBranchData → ProfileRoute (path: '/profile')
    └── ChangePasswordRoute (fst:auth, path: 'change-password')
    └── SystemSettingsRoute (path: 'system-settings')
```

Splash + auth screens are mounted outside the shell (direct GoRouter routes).

---

## 7. Feature Package Internal Structure

Each feature package follows this layout:

```
packages/features/<name>/
├── pubspec.yaml
├── lib/
│   ├── feature_<name>.dart       # PUBLIC BARREL — the only public API surface
│   └── src/
│       ├── di.dart               # Internal DI anchor (NOT exported)
│       ├── di.module.dart        # GENERATED micro-package module (exported)
│       ├── locator.dart          # Internal service locator shim (NOT exported)
│       ├── domain/
│       │   ├── entities/         # Domain entities (exported via barrel)
│       │   ├── repositories/     # Repository interfaces (NOT exported)
│       │   ├── services/         # Sync controllers (exported via barrel)
│       │   └── usecases/         # Use case classes (NOT exported)
│       ├── data/
│       │   ├── datasources/      # Remote data source interfaces + impls (NOT exported)
│       │   ├── local/            # Local data source interfaces + ObjectBox/Drift impls
│       │   ├── models/           # DTOs (NOT exported)
│       │   ├── repositories/     # Repository implementations (NOT exported)
│       │   └── sync/             # Sync adapters (NOT exported)
│       └── presentation/
│           ├── bloc/             # BLoCs, Cubits, States (exported via barrel)
│           ├── screens/          # Screens (exported via barrel)
│           ├── widgets/          # Feature widgets (exported via barrel)
│           └── <name>_routes.dart # Route definitions (exported via barrel)
└── test/
```

### Barrel Export Rules (enforced by `public_api_contracts_test.dart`)
- ✅ `src/di.module.dart` (Injectable module class only)
- ✅ `src/presentation/**` (routes, screens, widgets, BLoCs)
- ✅ `src/domain/entities/**` (domain entities)
- ✅ `src/domain/services/**` (sync controllers)
- ❌ `src/di.dart` (internal anchor)
- ❌ `src/locator.dart` (service locator)
- ❌ `src/data/**` (data layer internals)
- ❌ `src/domain/repositories/**` (repository interfaces)
- ❌ `src/domain/usecases/**` (use case classes)
- ❌ `package:firebase_*/` (raw Firebase SDK re-exports)

---

## 8. Design System Architecture

Package: `packages/app_ui/`

### Design Token Authorities (enforced by `design_system_boundaries_test.dart`)
Only `packages/app_ui/lib/src/` may define:
- `AppColorPalette`, `AppTheme`, `AppTypography`, `AppSpacing`, `AppRadius`
- `AppElevation`, `AppIconSize`, `AppDurations`, `AppBreakpoints`, `AppBorderWidth`
- `SemanticColors`

### Design System Boundaries
- `app_ui` must have **no** `feature_*` dependencies or imports.
- Widget files in `packages/app_ui/lib/src/widgets/` must not contain `Color(0x...)` or `Colors.xxx` (except allowed media files: `app_photo_view.dart`, `app_photo_view_fullscreen.dart`, `app_ui_showcase.dart`).
- Widgets must not embed hard-coded user-facing copy (no `Text('...')` with string literals).

---

## 9. Database Architecture

### ObjectBox (default)
- `packages/database/` — contains committed `objectbox.g.dart` (never delete/regenerate casually)
- `ObjectBoxModule` provides `Store` and `AtomicWriteCoordinator` to the DI container
- Each feature registers its own `ObjectBoxXxxDataSource` via `@LazySingleton`

### Drift (opt-in via `fst create --database drift`)
- `packages/database_drift/` renamed to `packages/database/` by CLI
- `DriftModule` provides `AppDatabase` and `AtomicWriteCoordinator` only
- Each feature registers its own `DriftXxxDataSource` via `@LazySingleton` in its `di.module.dart`
- Drift binding (`*.g.dart`) is git-ignored and regenerated by `tool/codegen.sh`

---

## 10. CI Architecture

Pipeline: `.github/workflows/ci.yml` — 30 jobs (all passing on branch `feat/foundation-certification`).

Key jobs:
| Job | Purpose |
|-----|---------|
| `changes` | Path filter — skips heavy jobs for docs-only PRs |
| `analyze` | `fvm flutter analyze` — zero warnings |
| `format` | `dart format --set-exit-if-changed` |
| `test` | `fvm flutter test` — unit + widget tests |
| `architecture` | Architecture guardrail tests (18 files) |
| `scaffold-smoke` | CLI scaffold test with various feature flags |
| `fixture-registration` | Golden test fixture registration |
| `golden-*` | macOS golden tests (tolerant comparator) |
| `objectbox-*` | ObjectBox-specific tests |
| `android-build` | Debug APK build |

**Flutter version:** Pinned at 3.44.0 via `.fvmrc`. All CI and local commands must use `fvm flutter` / `fvm dart`.

**iOS note:** Swift Package Manager must be disabled globally (`fvm flutter config --no-enable-swift-package-manager`) due to Firebase requiring iOS 15.0 and SPM target being hardcoded to iOS 13.0 in Flutter 3.44.0.
