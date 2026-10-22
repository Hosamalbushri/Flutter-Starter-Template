# Package Development Contract

> **Authoritative Engineering Contract for Workspace Packages**
> Every rule is classified under a strict 3-tier enforcement taxonomy:
> - **ENFORCED**: Backed by a deterministic repository-wide architecture test in `test/architecture/` or a mandatory CI gate.
> - **PARTIALLY ENFORCED**: Enforced in CLI unit tests or localized tests, but lacks a complete static workspace guardrail.
> - **DOCUMENTED ONLY**: Established as engineering policy/convention, but lacks an automated test assertion.

---

## 1. Governance & Enforcement Summary

| Rule ID | Rule Name | Category | Enforcement Tier | Risk Level if Breached | Enforcing Architecture Test / Mechanism |
|---------|-----------|----------|------------------|------------------------|-----------------------------------------|
| `RULE-01` | Package Naming & Location | Structure | **ENFORCED** | HIGH | `public_api_contracts_test.dart`, `package_layering_test.dart` |
| `RULE-02` | Single Public Barrel | Encapsulation | **ENFORCED** | HIGH | `public_api_contracts_test.dart` |
| `RULE-03` | Feature Barrel Export Restrictions | Encapsulation | **ENFORCED** | HIGH | `public_api_contracts_test.dart` |
| `RULE-04` | No Cross-Package Private `src/` Imports | Boundaries | **ENFORCED** | CRITICAL | `feature_boundaries_test.dart`, `design_system_boundaries_test.dart` |
| `RULE-05` | Cross-Feature Import Allowlist | Decoupling | **ENFORCED** | CRITICAL | `feature_boundaries_test.dart` |
| `RULE-06` | Relative Import Containment | Boundaries | **ENFORCED** | HIGH | `feature_boundaries_test.dart` |
| `RULE-07` | No Dependency on App Shell | Layering | **ENFORCED** | CRITICAL | `package_layering_test.dart` |
| `RULE-08` | Layer Rank DAG (No Upward/Cycles) | Layering | **ENFORCED** | CRITICAL | `package_layering_test.dart` |
| `RULE-09` | Micro-Package DI Self-Registration | Dependency Injection | **ENFORCED** | HIGH | `di_self_registration_test.dart`, `feature_boundaries_test.dart`, `di_boundaries_test.dart` |
| `RULE-10` | Load-Bearing DI Module Ordering | Dependency Injection | **ENFORCED** | CRITICAL | `di_module_ordering_test.dart`, `di_boundaries_test.dart` |
| `RULE-11` | No Foreign DI Module References | Dependency Injection | **ENFORCED** | HIGH | `di_boundaries_test.dart` |
| `RULE-12` | Design System Token Authority & UI Purity | Design System | **ENFORCED** | HIGH | `design_system_boundaries_test.dart`, `foundation_phase04_ui_guardrails_test.dart` |
| `RULE-13` | Symmetrical Feature Marker Coverage | Scaffolding | **ENFORCED** | HIGH | `feature_sentinel_integrity_test.dart`, `foundation_phase02_regression_test.dart`, CI `scaffold-smoke` |
| `RULE-14` | ObjectBox Schema UID Stability | Persistence | **ENFORCED** | CRITICAL | `objectbox_schema_integrity_test.dart` |
| `RULE-15` | `test_utils` Dev-Dependency Isolation | Dependencies | **ENFORCED** | MEDIUM | `package_layering_test.dart` |
| `RULE-16` | Scaffold Format Gate | Code Quality | **ENFORCED** | MEDIUM | CI `format` job (`dart format`) |
| `RULE-17` | Workspace Lockfile Enforcement | Dependencies | **ENFORCED** | LOW | `lockfile_reproducibility_test.dart`, CI `--enforce-lockfile` across all jobs |
| `RULE-18` | Release Signing & Conditional Firebase | Security / Build | **ENFORCED** | CRITICAL | `android_dependency_resolution_test.dart`, `foundation_phase01_regression_test.dart` |
| `RULE-19` | iOS Generic Branded Permissions | Platform | **ENFORCED** | HIGH | `ios_permission_strings_test.dart` |
| `RULE-20` | Release Secrets Preflight Fail-Fast | Security / CI | **ENFORCED** | HIGH | `release_secrets_preflight_test.dart` |
| `RULE-21` | Single Deep Link Intent Delivery | Navigation | **ENFORCED** | HIGH | `android_deep_link_test.dart` |
| `RULE-22` | Network Ownership of Authenticated Dio | Network / DI | **ENFORCED** | CRITICAL | `authenticated_dio_test.dart` |
| `RULE-23` | Domain Typed Failures & No-Throw UseCases | Domain Architecture | **ENFORCED** | MEDIUM | `domain_usecase_contract_test.dart` |
| `RULE-24` | Codegen Coverage for Tracked DI Modules | Codegen / CI | **ENFORCED** | HIGH | `di_module_codegen_coverage_test.dart` |
| `RULE-25` | Domain Layer UI & Framework Isolation | Domain Purity | **ENFORCED** | CRITICAL | `localization_and_ui_boundaries_test.dart` |
| `RULE-26` | Zero-Firebase Graceful Degradation | Observability | **ENFORCED** | HIGH | `firebase_optional_di_test.dart` |

---

## 2. Enforcement Gaps Resolution Summary

All 5 historical architectural gaps identified in the Foundation Audit have been closed with automated test suites in `test/architecture/`:

### GAP-01: ObjectBox Schema UID Stability (`RULE-14`) — ENFORCED
- **Status:** `ENFORCED`
- **Enforcement Test:** `test/architecture/objectbox_schema_integrity_test.dart`
- **Protection:** Verifies schema UID baselines, blocks property/entity UID mutations or drift, detects UID reuse, and guarantees that legitimate schema expansions maintain uniqueness without breaking on-device SQLite/ObjectBox databases. Distinguishes intentional Drift mode from accidental ObjectBox file omissions.

### GAP-02: Repository-Wide Sentinel Marker Balance & Coverage (`RULE-13`) — ENFORCED
- **Status:** `ENFORCED`
- **Enforcement Test:** `test/architecture/feature_sentinel_integrity_test.dart`
- **Protection:** Whole-repository AST and text scanner verifying symmetrical 1:1 matching of `:start` and `:end` sentinels, prohibiting unauthorized feature nesting, ensuring valid identifier formats, and asserting that simulated feature stripping leaves valid, balanced Dart syntax.

### GAP-03: Feature DI Self-Registration Annotation Guard (`RULE-09`) — ENFORCED
- **Status:** `ENFORCED`
- **Enforcement Test:** `test/architecture/di_self_registration_test.dart`
- **Protection:** AST annotation scanner guaranteeing that all concrete local/remote data sources and repository implementations carry `@LazySingleton` or `@injectable`, preventing runtime resolution crashes. Confirms zero duplicate interface bindings and ensures generated `di.module.dart` stays in sync with definitions.

### GAP-04: Domain UseCase No-Throw Contract (`RULE-23`) — ENFORCED
- **Status:** `ENFORCED`
- **Enforcement Test:** `test/architecture/domain_usecase_contract_test.dart`
- **Protection:** AST method and return-type analyzer ensuring all feature use cases extend `UseCase` or `NoParamUseCase`, return `Future<Result<Output>>`, and contain no uncaught raw `throw` expressions in `call()`.

### GAP-05: Workspace Lockfile Synchronization (`RULE-17`) — ENFORCED
- **Status:** `ENFORCED`
- **Enforcement Test:** `test/architecture/lockfile_reproducibility_test.dart` + `.github/workflows/ci.yml`
- **Protection:** Validates that `pubspec.lock` and `published/cli/pubspec.lock` are committed and tracked in git, ensures all workspace packages have `resolution: workspace`, verifies sha256 checksums for hosted packages, and enforces `--enforce-lockfile` across all dependency resolution steps in GitHub Actions CI.

---

## 3. The 26 Rules: Detailed Specifications

### RULE-01: Package Naming & Directory Placement
- **Tier:** `ENFORCED`
- **Specification:**
  - Feature packages must reside under `packages/features/<name>/` and have `name: feature_<name>` in `pubspec.yaml`.
  - Reusable workspace packages must reside under `packages/<name>/` and have `name: <name>`.
  - Every package must be registered under `workspace:` in the root `pubspec.yaml`.
- **Verification:** `public_api_contracts_test.dart`, `package_layering_test.dart`.

### RULE-02: Single Public Barrel
- **Tier:** `ENFORCED`
- **Specification:**
  - Every workspace package exposes exactly one top-level file in `lib/`: `lib/<package_name>.dart`.
  - All implementation files must reside in `lib/src/`.
  - Allowed exceptions: `packages/database/lib/objectbox.g.dart`, `packages/localization/lib/l10n/`.
- **Verification:** `public_api_contracts_test.dart` (`validatePackageLibStructure`).

### RULE-03: Feature Barrel Export Restrictions
- **Tier:** `ENFORCED`
- **Specification:**
  - Feature barrels (`lib/feature_<name>.dart`) may ONLY export:
    - `src/di.module.dart` (showing the micro-package module class only)
    - `src/presentation/**` (routes, screens, widgets, BLoCs, cubits, states)
    - `src/domain/entities/**` (immutable domain entities)
    - `src/domain/services/**` (sync lifecycle controllers)
  - Barrels MUST NEVER export: `src/di.dart`, `src/locator.dart`, `src/data/**`, `src/domain/repositories/**`, `src/domain/usecases/**`.
  - Barrels MUST NEVER re-export raw SDKs (`firebase_*`, `shared_preferences`, `flutter_secure_storage`).
- **Verification:** `public_api_contracts_test.dart` (`validateBarrelExports`).

### RULE-04: No Cross-Package Private `src/` Imports
- **Tier:** `ENFORCED`
- **Specification:**
  - No file in `lib/` or `test/` may import `package:<other>/src/...` where `<other>` is not the owning package.
- **Verification:** `feature_boundaries_test.dart` (`scanDirectivesForBoundaryViolations`), `design_system_boundaries_test.dart`.

### RULE-05: Cross-Feature Import Allowlist
- **Tier:** `ENFORCED`
- **Specification:**
  - Feature packages may not import another feature package outside `_allowedCrossFeatureImports` in `feature_boundaries_test.dart`.
  - Current allowlist: `feature_bookmarks -> feature_collections` (Add to Collection sheet) and `feature_profile -> feature_auth` (Delete Account flow).
  - Every allowlisted entry must have a live consumer (no stale entries allowed).
- **Verification:** `feature_boundaries_test.dart`.

### RULE-06: Relative Import Containment
- **Tier:** `ENFORCED`
- **Specification:**
  - Relative import directives (`../`) must never navigate outside the package's `lib/` directory.
- **Verification:** `feature_boundaries_test.dart` (`scanDirectivesForBoundaryViolations`).

### RULE-07: No Dependency on Application Shell
- **Tier:** `ENFORCED`
- **Specification:**
  - No workspace package under `packages/` or `published/` may declare a dependency on `flutter_starter_template` (root app).
- **Verification:** `package_layering_test.dart` (`[depends-on-application-shell]`).

### RULE-08: Layer Rank DAG (Cycle-Free)
- **Tier:** `ENFORCED`
- **Specification:**
  - Layer Ranks:
    - Rank 0: `architecture`, `rev_sync`
    - Rank 1: `app_platform`, `sync_connectivity_plus`
    - Rank 2: `analytics`, `config`, `database`, `network`, `storage`, `document_engine`
    - Rank 3: `shared_contracts`, `app_ui`, `localization`, `theme`, `shared_ui`, `test_utils`
    - Rank 4: All `feature_*` packages
    - Rank 5: Root Application Shell (`lib/`)
  - Dependencies must strictly flow downward (Rank $A \rightarrow$ Rank $B$ where $B < A$).
  - Upward dependencies, same-layer dependencies, and cyclic references are strictly forbidden.
- **Verification:** `package_layering_test.dart` (`validateLayeringAndCategories`, `detectDependencyCycles`).

### RULE-09: Micro-Package DI Self-Registration
- **Tier:** `ENFORCED`
- **Specification:**
  - Feature data sources must register themselves via `@LazySingleton(as: Interface)` in their own `lib/src/` files.
  - The app-root database modules (`DriftModule`, `ObjectBoxModule`) provide only engine primitives (`AppDatabase`, `Store`, `AtomicWriteCoordinator`, `SyncCursorStore`). They must never import feature data sources.
- **Verification:** `di_self_registration_test.dart`, `feature_boundaries_test.dart`.

### RULE-10: Load-Bearing DI Module Ordering
- **Tier:** `ENFORCED`
- **Specification:**
  - In `lib/app/di/injection.dart`, infrastructure modules must precede feature modules.
  - `StoragePackageModule` must precede `NetworkPackageModule`.
  - `SharedContractsPackageModule` must precede `FeatureNotificationsPackageModule`.
- **Verification:** `di_module_ordering_test.dart`, `di_boundaries_test.dart`.

### RULE-11: No Foreign DI Module References
- **Tier:** `ENFORCED`
- **Specification:**
  - Feature packages must not import or reference another feature's `Feature*PackageModule` or `init*Feature` functions.
- **Verification:** `di_boundaries_test.dart` (`validateFeatureDiFile`).

### RULE-12: Design System Token Authority & UI Purity
- **Tier:** `ENFORCED`
- **Specification:**
  - Token authority: Design tokens (`AppColorPalette`, `AppTheme`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation`, `AppIconSize`, `AppDurations`, `AppBreakpoints`, `AppBorderWidth`, `SemanticColors`) are defined exclusively in `packages/app_ui/lib/src`.
  - `app_ui` has zero dependencies or imports of `feature_*`.
  - Presentation code must not define raw colors (`Color(0x...)`, `Colors.xxx`).
  - Shared UI widgets must not embed hardcoded user-facing copy.
- **Verification:** `design_system_boundaries_test.dart`, `foundation_phase04_ui_guardrails_test.dart`.

### RULE-13: Symmetrical Feature Marker Coverage
- **Tier:** `ENFORCED`
- **Specification:**
  - Optional feature code must be enclosed in exact, balanced sentinel comments: `// fst:feature:<name>:start` ... `// fst:feature:<name>:end`.
  - Sentinels must never be nested inside other feature sentinels (with the sole exception of documented sub-feature actions like quickActions).
  - Routing primitives must use `_router` sentinel; backend-only infrastructure must use `_infra`.
- **Verification:** `feature_sentinel_integrity_test.dart`, `foundation_phase02_regression_test.dart`, CI `scaffold-smoke`.

### RULE-14: ObjectBox Schema UID Stability
- **Tier:** `ENFORCED`
- **Specification:**
  - `packages/database/lib/objectbox.g.dart` must never be deleted or regenerated without following the official ObjectBox schema migration procedure.
  - Baseline UIDs are permanently pinned and verified against accidental drift or UID reuse.
  - Excluded from `tool/codegen.sh`.
- **Verification:** `objectbox_schema_integrity_test.dart`.

### RULE-15: `test_utils` Dev-Dependency Isolation
- **Tier:** `ENFORCED`
- **Specification:**
  - `packages/test_utils` may only be declared in `dev_dependencies:`. Never in `dependencies:`.
- **Verification:** `package_layering_test.dart` (`devTestUtilities` category rule).

### RULE-16: Scaffold Format Gate
- **Tier:** `ENFORCED`
- **Specification:**
  - All files generated by CLI or written by developers must pass `dart format --set-exit-if-changed .` without changes.
- **Verification:** CI `format` job.

### RULE-17: Workspace Lockfile Enforcement
- **Tier:** `ENFORCED`
- **Specification:**
  - `pubspec.lock` and `published/cli/pubspec.lock` must be committed and enforced during project scaffolding and across all CI dependency resolution steps.
- **Verification:** `lockfile_reproducibility_test.dart`, CLI `create_command.dart` (`--enforce-lockfile`), `.github/workflows/ci.yml`.

### RULE-18: Release Signing Security & Conditional Firebase
- **Tier:** `ENFORCED`
- **Specification:**
  - Release Android builds must never fall back to debug signing keystore.
  - Missing production keystore must throw `GradleException`.
  - Google Services plugin must only apply when `googleServicesFile.exists()`.
- **Verification:** `android_dependency_resolution_test.dart`, `foundation_phase01_regression_test.dart`.

### RULE-19: iOS Generic Branded Permissions
- **Tier:** `ENFORCED`
- **Specification:**
  - Permission descriptions in `ios/Runner/Info.plist` must be non-empty, must not name template features ("bookmark", "collection"), must interpolate `$(APP_DISPLAY_NAME)`, and media keys must sit inside `fst:feature:bookmarks`.
- **Verification:** `ios_permission_strings_test.dart`.

### RULE-20: Release Secrets Preflight Fail-Fast
- **Tier:** `ENFORCED`
- **Specification:**
  - Every secret/var consumed by `release.yml` jobs must be listed in the job's `required=( ... )` bash preflight array.
- **Verification:** `release_secrets_preflight_test.dart`.

### RULE-21: Single Deep Link Intent Delivery
- **Tier:** `ENFORCED`
- **Specification:**
  - `AndroidManifest.xml` must configure `android:launchMode="singleTop"`, `flutter_deeplinking_enabled="true"`, and contain exactly one `ACTION_VIEW` intent filter.
- **Verification:** `android_deep_link_test.dart`.

### RULE-22: Network Ownership of Authenticated Dio
- **Tier:** `ENFORCED`
- **Specification:**
  - The unnamed authenticated `Dio provideDio(...)` provider is owned exclusively by `packages/network/lib/src/network_module.dart`.
  - No feature package may provide or register its own `Dio`.
- **Verification:** `authenticated_dio_test.dart`.

### RULE-23: Domain Typed Failures & No-Throw UseCases
- **Tier:** `ENFORCED`
- **Specification:**
  - Domain use cases must extend `UseCase` or `NoParamUseCase`, return `Future<Result<Output>>`, and never throw uncaught exceptions in `call()`.
  - Failures must subclass `Failure` (from `packages/architecture`).
- **Verification:** `domain_usecase_contract_test.dart`.

### RULE-24: Codegen Coverage for Tracked DI Modules
- **Tier:** `ENFORCED`
- **Specification:**
  - Every committed `di.module.dart` file on disk must be covered by the rebuild loop in `tool/codegen.sh` and its owning package must declare `build_runner`.
- **Verification:** `di_module_codegen_coverage_test.dart`.

### RULE-25: Domain Layer UI & Framework Isolation
- **Tier:** `ENFORCED`
- **Specification:**
  - Domain packages (`architecture`, `shared_contracts`, `rev_sync`) and feature `domain/` layers must never import `flutter/material.dart`, `flutter/widgets.dart`, `localization/localization.dart`, `go_router`, or `flutter_bloc`.
- **Verification:** `localization_and_ui_boundaries_test.dart`.

### RULE-26: Zero-Firebase Graceful Degradation
- **Tier:** `ENFORCED`
- **Specification:**
  - When `kFirebaseEnabled == false`, `AnalyticsService`, `CrashReporter`, and `PerformanceTracker` resolve cleanly to no-op implementations.
- **Verification:** `firebase_optional_di_test.dart`.
