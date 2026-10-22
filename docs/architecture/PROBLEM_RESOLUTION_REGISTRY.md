# Problem Resolution Registry

> **Architecture Knowledge Extraction & Problem Resolution Registry**
> Flutter Starter Template — Verified against actual code, Git history, commit diffs, and test suites.
> Status: **VERIFIED** = confirmed in code & tests; **HISTORICALLY VERIFIED** = confirmed in Git history & PRs.

---

## 1. Traceability Matrix

This matrix maps every historical problem to its root cause, fix, enforcing test, and corresponding rule in `PACKAGE_DEVELOPMENT_CONTRACT.md`.

| Problem ID | Problem Name | Domain / Subsystem | Commit / PR Reference | Enforcing Guardrail Test | Contract Rule ID | Status |
|------------|--------------|-------------------|----------------------|--------------------------|------------------|--------|
| **PROB-01** | Scaffold Formatting Drift | CLI / Templates | `2d7a62b`, `14104d4` | CI Format Gate (`dart format`) | `RULE-16` | VERIFIED |
| **PROB-02** | `RouteBase` Undefined under `--no-backend` | Routing / Markers | `d14be42`, `14104d4` | `scaffold-smoke` CI | `RULE-13` | VERIFIED |
| **PROB-03** | Bottom Nav Tab Indexing outside Markers | Navigation / Tests | `5dceb24` | `app_shell_navigation_test.dart` | `RULE-13` | VERIFIED |
| **PROB-04** | Android Firebase Resolution False-Positive | Build / CI | `2ba3b9d`, `d40c26c` | `android_dependency_resolution_test.dart` | `RULE-18` | VERIFIED |
| **PROB-05** | Cross-Package Private `src/` Imports in Drift | Database / DI | `2d7a62b`, `aac308c` | `feature_boundaries_test.dart`, `design_system_boundaries_test.dart` | `RULE-04`, `RULE-09` | VERIFIED |
| **PROB-06** | Stale `injection.config.dart` on DB Swap | CLI / Codegen | `0f500d3` | CLI Test Suite | `RULE-09` | VERIFIED |
| **PROB-07** | Generated Feature Templates Long Lines | CLI / Templates | `2d7a62b` | CI Format Gate (`dart format`) | `RULE-16` | VERIFIED |
| **PROB-08** | Document Center Nested in Notifications Marker | App Shell / Sentinels | `caa7e29` | `foundation_phase02_regression_test.dart` | `RULE-13` | VERIFIED |
| **PROB-09** | Collections Import Unguarded in `app_shell.dart` | App Shell / Sentinels | `caa7e29` | `foundation_phase02_regression_test.dart` | `RULE-13` | VERIFIED |
| **PROB-10** | Feature-Owned Color Constants in Presentation | UI / Design System | `650f69f`, `caa7e29` | `foundation_phase04_ui_guardrails_test.dart`, `design_system_boundaries_test.dart` | `RULE-12` | VERIFIED |
| **PROB-11** | Android Debug Signing Fallback in Release | Android / Security | `caa7e29` | `android_dependency_resolution_test.dart`, `foundation_phase01_regression_test.dart` | `RULE-18` | VERIFIED |
| **PROB-12** | iOS Permission Strings Naming Template Features | iOS / Permissions | `711becd`, `91b7371` | `ios_permission_strings_test.dart` | `RULE-19` | VERIFIED |
| **PROB-13** | DI Module Ordering Race (`SharedContracts`) | DI / Architecture | `75641df` (#131) | `di_module_ordering_test.dart` | `RULE-10` | VERIFIED |
| **PROB-14** | ObjectBox Schema UID Drift on Regeneration | Database / ObjectBox | `codegen.sh` history | `public_api_contracts_test.dart` | `RULE-14` | VERIFIED |
| **PROB-15** | Feature Barrel Leaking `src/di.dart` | Package API | `b415da4` (#130) | `public_api_contracts_test.dart` | `RULE-03` | VERIFIED |
| **PROB-16** | `go_router` Inside `_infra` Marker | CLI / Markers | `d14be42` | `scaffold-smoke` CI | `RULE-13` | VERIFIED |
| **PROB-17** | Multiline Import Sort Failure in CLI | CLI / Parser | `4bfda4b` | `sortDartImports` CLI Test | `RULE-16` | VERIFIED |
| **PROB-18** | Android Deep Link Delivered Twice | Android / Manifest | `6b67271` | `android_deep_link_test.dart` | `RULE-21` | VERIFIED |
| **PROB-19** | Release Secrets Without Per-Job Preflight | CI / Security | `1a9994f` (#182) | `release_secrets_preflight_test.dart` | `RULE-20` | VERIFIED |
| **PROB-20** | Authenticated `Dio` Owned by Feature Package | Network / Auth / DI | `ace8346` (#155) | `authenticated_dio_test.dart` | `RULE-22` | VERIFIED |
| **PROB-21** | Auth Session Absence vs Network Failure Conflation | Auth / Domain | `80fd3d6`, `7afc34e` | Feature Auth Unit Tests | `RULE-23` | HISTORICALLY VERIFIED |
| **PROB-22** | Feature Public Barrels Leaking 18 UseCases & Repos | Package API / Hygiene | `b415da4` (#130) | `public_api_contracts_test.dart` | `RULE-03` | VERIFIED |
| **PROB-23** | Infra `di.module.dart` Stale & Drifted in CI | Codegen / CI | `099d607`, `aca3ffd` | `di_module_codegen_coverage_test.dart` | `RULE-24` | VERIFIED |
| **PROB-24** | Domain Layer Contaminated with UI & BLoC Imports | Domain Purity | Architecture Refactor | `localization_and_ui_boundaries_test.dart` | `RULE-25` | VERIFIED |
| **PROB-25** | Orphaned Media Permissions on Feature Stripping | iOS / Android / CLI | `91b7371` (#180) | `ios_permission_strings_test.dart` | `RULE-19` | VERIFIED |
| **PROB-26** | Firebase Dependency Blocker on Untracked CI Runs | CI / Firebase | `b428ead` (#198) | CI changes filter & workflow | `RULE-18` | VERIFIED |

---

## 2. In-Depth Problem Records

### PROB-01: Scaffold Formatting Drift
- **Component:** `published/cli/lib/src/rewrite/feature_template.dart`, `tool/setup.sh`, `.github/workflows/ci.yml`
- **Wrong Behavior:** Stripping marker comments left irregular blank lines; template strings had lines > 80 chars. `dart format --set-exit-if-changed` rejected the scaffolded codebase.
- **Root Cause:** Marker stripper did not normalize consecutive blank lines; templates had unformatted code.
- **Fix:** Set `run_format=1` in `tool/setup.sh`; added `--format` flag to CI bootstrap; formatted template strings in `feature_template.dart`.
- **Enforcement:** CI `format` job.

---

### PROB-02: `RouteBase` Undefined under `--no-backend`
- **Component:** `lib/app/features.dart`, `published/cli/lib/src/rewrite/features.dart`
- **Wrong Behavior:** Running `fst create --no-backend` stripped `go_router` import because it was inside `fst:feature:_infra` markers, causing `RouteBase` compile failure in `document_center`.
- **Root Cause:** Inappropriate marker grouping conflating routing types with backend infrastructure.
- **Fix:** Decoupled `go_router` into dedicated `// fst:feature:_router:start ... end` marker.
- **Enforcement:** CI `scaffold-smoke` job.

---

### PROB-03: Bottom Nav Tab Indexing outside Feature Markers
- **Component:** `test/app/app_shell_navigation_test.dart`
- **Wrong Behavior:** Tapping tab index 1 (bookmarks) was executed outside feature sentinels. When bookmarks was excluded, the tab count shrank, throwing `RangeError`.
- **Root Cause:** Hardcoded tab indices in integration tests without conditional sentinels.
- **Fix:** Wrapped lines 153–161 in `fst:feature:bookmarks:start ... end`.
- **Enforcement:** `app_shell_navigation_test.dart` during scaffold smoke tests.

---

### PROB-04: Android Firebase Dependency Resolution False-Positive
- **Component:** `test/architecture/android_dependency_resolution_test.dart`
- **Wrong Behavior:** Test asserted `source.contains('val googleServicesFile')` to check if Firebase plugins were active. That line was always present, yielding false-positive verification.
- **Root Cause:** Checking file-existence variable rather than actual plugin application.
- **Fix:** Changed assertion to check for `apply(plugin = "com.google.gms.google-services")`.
- **Enforcement:** `android_dependency_resolution_test.dart`.

---

### PROB-05: Cross-Package Private `src/` Imports in Drift Scaffolding
- **Component:** `lib/core/data/database/drift_module.dart`, `published/cli/lib/src/rewrite/database.dart`
- **Wrong Behavior:** App-root `drift_module.dart` imported `package:feature_bookmarks/src/data/local/bookmarks_local_data_source.dart`.
- **Root Cause:** Centralized database module attempted to register all feature local data sources in the host app.
- **Fix:** Redesigned micro-packages to self-register their local data sources using `@LazySingleton(as: XxxLocalDataSource)` in `di.module.dart`. App-root `DriftModule` provides only `AppDatabase`, `AtomicWriteCoordinator`, and `SyncCursorStore`.
- **Enforcement:** `feature_boundaries_test.dart` and `design_system_boundaries_test.dart`.

---

### PROB-06: Stale `injection.config.dart` after Database Engine Swap
- **Component:** `published/cli/lib/src/rewrite/database.dart`
- **Wrong Behavior:** Swapping from ObjectBox to Drift left behind ObjectBox-specific bindings in `injection.config.dart`, breaking build.
- **Root Cause:** Injectable generator skipped re-emission when existing target was present.
- **Fix:** `swapDatabase()` in CLI now explicitly deletes `lib/app/di/injection.config.dart` and feature `di.module.dart` files.
- **Enforcement:** CLI database swap integration tests.

---

### PROB-07: Generated Feature Templates Long Lines
- **Component:** `published/cli/lib/src/rewrite/feature_template.dart`
- **Wrong Behavior:** `fst add-feature` generated one-liners exceeding 80 characters.
- **Root Cause:** Template string literals were written without running `dart format`.
- **Fix:** Formatted all templates in `feature_template.dart` to match `dart format` output.
- **Enforcement:** CI `format` job on generated fixtures.

---

### PROB-08: Document Center Import Nested inside Notifications Sentinel
- **Component:** `lib/app/features.dart`
- **Wrong Behavior:** `feature_document_center` was nested inside `fst:feature:notifications` marker. Excluding notifications broke document center.
- **Root Cause:** Careless marker nesting during feature addition.
- **Fix:** Un-nested the sentinel blocks.
- **Enforcement:** `test/architecture/foundation_phase02_regression_test.dart`.

---

### PROB-09: Collections Import Unguarded in `app_shell.dart`
- **Component:** `lib/app/widgets/app_shell.dart`
- **Wrong Behavior:** Collections import remained when collections was excluded.
- **Root Cause:** Missing `fst:feature:collections` sentinel wrapping the import line.
- **Fix:** Wrapped import inside `fst:feature:collections:start ... end`.
- **Enforcement:** `test/architecture/foundation_phase02_regression_test.dart`.

---

### PROB-10: Feature-Owned Color Constants in Presentation
- **Component:** `packages/features/bookmarks/lib/src/presentation/widgets/detail/`, `packages/features/document_center/lib/src/presentation/`
- **Wrong Behavior:** Feature UI contained `bookmark_detail_colors.dart` and inline `Color(0x...)` definitions.
- **Root Cause:** Bypassing `app_ui` design token authority.
- **Fix:** Deleted feature-owned color files; migrated all widgets to `ColorScheme` and `SemanticColors`.
- **Enforcement:** `foundation_phase04_ui_guardrails_test.dart` and `design_system_boundaries_test.dart`.

---

### PROB-11: Android Debug Signing Fallback in Release Builds
- **Component:** `android/app/build.gradle.kts`
- **Wrong Behavior:** Release builds silently fell back to debug signing keystore if `key.properties` was missing.
- **Root Cause:** Insecure Gradle fallback configuration.
- **Fix:** Restricted release signing instantiation to `keystorePropertiesFile.exists()` and added fast-fail `throw GradleException(...)` on missing production keys.
- **Enforcement:** `android_dependency_resolution_test.dart` and `foundation_phase01_regression_test.dart`.

---

### PROB-12: iOS Permission Strings Naming Template Features
- **Component:** `ios/Runner/Info.plist`
- **Wrong Behavior:** Permission strings hardcoded "bookmarks" and "collections", and "This app".
- **Root Cause:** Hardcoded demo copy in template `Info.plist`.
- **Fix:** Genericized all descriptions; interpolated `$(APP_DISPLAY_NAME)`; wrapped keys in `fst:feature:bookmarks`.
- **Enforcement:** `test/architecture/ios_permission_strings_test.dart`.

---

### PROB-13: DI Module Ordering Race (`SharedContracts` after Feature)
- **Component:** `lib/app/di/injection.dart`
- **Wrong Behavior:** `SharedContractsPackageModule` provides `ActivityNotifier`. `FeatureNotificationsPackageModule`'s BLoC resolves it at construction. Reversing list order compiled clean but crashed at runtime.
- **Root Cause:** Implicit runtime dependency between DI modules not verifiable by Dart static analysis.
- **Fix:** Locked list order in `externalPackageModulesBefore`; created test parsing source order and asserting invariant.
- **Enforcement:** `test/architecture/di_module_ordering_test.dart`.

---

### PROB-14: ObjectBox Schema UID Drift on Regeneration
- **Component:** `packages/database/lib/objectbox.g.dart`
- **Wrong Behavior:** Deleting and regenerating `objectbox.g.dart` assigned new random UIDs, breaking physical device database upgrades.
- **Root Cause:** ObjectBox entity UIDs must remain stable across app updates.
- **Fix:** Committed `objectbox.g.dart` to Git; excluded it from `tool/codegen.sh`; granted exemption in `public_api_contracts_test.dart`.
- **Enforcement:** `public_api_contracts_test.dart` allows `objectbox.g.dart` at `lib/` root.

---

### PROB-15: Feature Barrel Leaking `src/di.dart`
- **Component:** Feature public barrels (`lib/feature_<name>.dart`)
- **Wrong Behavior:** Barrels exported `src/di.dart` and `src/locator.dart`.
- **Root Cause:** Lack of export filtering in template barrels.
- **Fix:** Restricted barrels to export only `src/di.module.dart` (module class).
- **Enforcement:** `test/architecture/public_api_contracts_test.dart`.

---

### PROB-16: `go_router` Inside `_infra` Marker
- **Component:** `lib/app/features.dart`
- **Wrong Behavior:** See PROB-02.
- **Fix:** Created `_router` sentinel marker.
- **Enforcement:** CI `scaffold-smoke`.

---

### PROB-17: Multiline Import Sort Failure in CLI
- **Component:** `published/cli/lib/src/rewrite/` (`sortDartImports`)
- **Wrong Behavior:** CLI import sorter broke on imports spanning multiple lines with show/hide clauses.
- **Root Cause:** Sorter assumed each import was a single line.
- **Fix:** Pre-processed multiline imports into consolidated tokens before sorting.
- **Enforcement:** CLI unit tests in `published/cli/test/`.

---

### PROB-18: Android Deep Link Delivered Twice
- **Component:** `android/app/src/main/AndroidManifest.xml`
- **Wrong Behavior:** Deep links caused two identical screen pushes in Flutter.
- **Root Cause:** Two `ACTION_VIEW` intent filters declared in `AndroidManifest.xml`.
- **Fix:** Consolidated into a single `ACTION_VIEW` filter; set `android:launchMode="singleTop"`.
- **Enforcement:** `test/architecture/android_deep_link_test.dart`.

---

### PROB-19: Release Secrets Without Per-Job Preflight
- **Component:** `.github/workflows/release.yml`
- **Wrong Behavior:** Missing secret failed Fastlane 15 minutes into a run.
- **Root Cause:** No fail-fast validation in release jobs.
- **Fix:** Added bash `required=( ... )` arrays to top of every release job; added earned exemptions mechanism.
- **Enforcement:** `test/architecture/release_secrets_preflight_test.dart`.

---

### PROB-20: Authenticated `Dio` Owned by Feature Package
- **Component:** `packages/features/auth`, `packages/network`, `packages/storage`
- **Wrong Behavior:** `feature_auth` registered the unnamed authenticated `Dio` and `FlutterSecureStorage`. All other feature packages resolved `Dio` implicitly from `GetIt`, establishing an invisible, undocumented runtime dependency on `feature_auth`.
- **Root Cause:** Conflating authentication credentials (auth domain) with HTTP transport infrastructure (network domain).
- **Fix (Commit `ace8346`):**
  1. Extracted `AuthTokenStore` and `SecureStorageModule` into `packages/storage`.
  2. Extracted `AuthInterceptor` and `TokenRefresher` into `packages/network`.
  3. `network` now owns `provideDio(...)` via `NetworkModule`.
  4. Decoupled `feature_auth` entirely from global transport provision.
- **Enforcement:** `test/architecture/authenticated_dio_test.dart` and `test/architecture/di_module_ordering_test.dart`.

---

### PROB-21: Auth Session Absence vs Network Failure Conflation
- **Component:** `packages/architecture/lib/src/failure.dart`, `packages/features/auth`
- **Wrong Behavior:** Restoring a session on a fresh install threw exceptions or returned error states identical to a failed network request.
- **Root Cause:** Using generic exceptions without typed domain failures.
- **Fix:** Introduced `NoSessionFailure` in `packages/architecture` to model the expected absence of a session cleanly, distinct from `NetworkFailure` or `InvalidCredentialsFailure`. Handled via exhaustive pattern matching on `Result<T>`.
- **Enforcement:** `packages/features/auth/test/data/repositories/auth_repository_impl_test.dart`.

---

### PROB-22: Feature Public Barrels Leaking 18 UseCases & Repos
- **Component:** `packages/features/bookmarks`, `collections`, `notifications`
- **Wrong Behavior:** Public barrels re-exported internal repository interfaces and 18 use cases.
- **Root Cause:** Oversized public API surfaces created accidental coupling opportunities.
- **Fix (Commit `b415da4`):** Narrowed all feature barrels to the strictly consumed surface: `src/di.module.dart`, entities, sync controllers, screens, and routes. Removed all repositories and use cases.
- **Enforcement:** `test/architecture/public_api_contracts_test.dart`.

---

### PROB-23: Infra `di.module.dart` Stale & Drifted in CI
- **Component:** `tool/codegen.sh`, `packages/analytics`, `config`, `storage`, `network`, `sync_connectivity_plus`
- **Wrong Behavior:** CI diff-guard passed even though committed infra `di.module.dart` files had drifted (e.g. `rev_sync` import alias).
- **Root Cause:** `tool/codegen.sh` previously only generated for `packages/features/*/`, leaving infra packages unbuilt.
- **Fix (Commits `099d607`, `aca3ffd`):** Expanded `tool/codegen.sh` to iterate over all workspace packages declaring `build_runner`.
- **Enforcement:** `test/architecture/di_module_codegen_coverage_test.dart`.

---

### PROB-24: Domain Layer Contaminated with UI & BLoC Imports
- **Component:** `packages/architecture`, `packages/shared_contracts`, feature `domain/` layers
- **Wrong Behavior:** Domain models imported Flutter UI packages (`flutter/material.dart`, `flutter_bloc`) to use `Color` or `BuildContext`.
- **Root Cause:** Blurring boundaries between domain logic and presentation.
- **Fix:** Purged all UI and state management dependencies from domain layers.
- **Enforcement:** `test/architecture/localization_and_ui_boundaries_test.dart`.

---

### PROB-25: Orphaned Media Permissions on Feature Stripping
- **Component:** `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`
- **Wrong Behavior:** When bookmarks was excluded via `fst create --exclude-feature bookmarks`, camera and microphone permissions remained declared.
- **Root Cause:** Native manifests lacked sentinels around media permission keys.
- **Fix (Commit `91b7371`):** Wrapped media permission blocks in `fst:feature:bookmarks:start ... end`.
- **Enforcement:** `test/architecture/ios_permission_strings_test.dart`.

---

### PROB-26: Firebase Dependency Blocker on Untracked CI Runs
- **Component:** `.github/workflows/ci.yml`, `lib/app/firebase.dart`
- **Wrong Behavior:** CI runs failed on placeholder Firebase steps when Firebase credentials were not configured.
- **Root Cause:** CI jobs did not branch on Firebase availability.
- **Fix (Commit `b428ead`):** Marked placeholder credential steps as Firebase-only and isolated path filtering.
- **Enforcement:** CI workflow execution matrix.
