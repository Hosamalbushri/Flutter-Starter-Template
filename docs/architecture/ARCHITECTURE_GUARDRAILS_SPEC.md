# Architecture Guardrails Specification

> Complete specification of all automated architectural tests and guardrails in `test/architecture/`.
> Every test in this suite is executed on CI (`fvm flutter test test/architecture/`) as a mandatory status check.

---

## 1. Guardrails Catalog

| # | Guardrail Test File | Target Domain | Enforcement Level |
|---|---------------------|---------------|-------------------|
| 1 | `feature_boundaries_test.dart` | Modular Boundaries & Private Imports | Machine-Enforced (E) |
| 2 | `package_layering_test.dart` | Package Categories, Layers & DAG Cycles | Machine-Enforced (E) |
| 3 | `public_api_contracts_test.dart` | Public Barrels & Export Restrictions | Machine-Enforced (E) |
| 4 | `di_boundaries_test.dart` | DI Scopes & Service Locator Access | Machine-Enforced (E) |
| 5 | `di_module_ordering_test.dart` | DI Module Registration Sequence | Machine-Enforced (E) |
| 6 | `di_module_codegen_coverage_test.dart` | Codegen Script Coverage for DI Modules | Machine-Enforced (E) |
| 7 | `design_system_boundaries_test.dart` | Design Tokens, UI Isolation & Raw Colors | Machine-Enforced (E) |
| 8 | `localization_and_ui_boundaries_test.dart` | Domain Layer Purity (No UI/BLoC/L10n) | Machine-Enforced (E) |
| 9 | `feature_module_contracts_test.dart` | FeatureModule Registration & Mapping | Machine-Enforced (E) |
| 10 | `authenticated_dio_test.dart` | Network Ownership of Authenticated Dio | Machine-Enforced (E) |
| 11 | `firebase_optional_di_test.dart` | Zero-Firebase DI Resolution & Fallbacks | Machine-Enforced (E) |
| 12 | `foundation_phase01_regression_test.dart` | Android Signing & Document Engine Licensing | Machine-Enforced (E) |
| 13 | `foundation_phase02_regression_test.dart` | Sentinel Marker Isolation & Nesting | Machine-Enforced (E) |
| 14 | `foundation_phase04_ui_guardrails_test.dart` | Hardcoded Colors & String Literals | Machine-Enforced (E) |
| 15 | `android_deep_link_test.dart` | Deep Link Intent Single Delivery | Machine-Enforced (E) |
| 16 | `android_dependency_resolution_test.dart` | Gradle Pinning & Release Signing Security | Machine-Enforced (E) |
| 17 | `ios_permission_strings_test.dart` | iOS Generic Copy & Marker Scoping | Machine-Enforced (E) |
| 18 | `release_secrets_preflight_test.dart` | Release CI Fail-Fast Secrets Preflight | Machine-Enforced (E) |
| 19 | `objectbox_schema_integrity_test.dart` | ObjectBox Schema Baseline & UID Stability | Machine-Enforced (E) |
| 20 | `feature_sentinel_integrity_test.dart` | Symmetrical Sentinel Coverage & Stripping | Machine-Enforced (E) |
| 21 | `di_self_registration_test.dart` | Feature DI Self-Registration Annotations | Machine-Enforced (E) |
| 22 | `domain_usecase_contract_test.dart` | Domain UseCase Typed Result & No-Throw | Machine-Enforced (E) |
| 23 | `lockfile_reproducibility_test.dart` | Workspace Lockfile & CI Pinning Enforcement | Machine-Enforced (E) |

---

## 2. Detailed Guardrail Specifications

### 2.1 `feature_boundaries_test.dart`
- **Purpose:** Enforces that feature packages remain strictly decoupled, private `src/` files are never imported across package boundaries, and relative imports do not escape their package roots.
- **Rules Enforced:**
  1. *No Cross-Feature Imports outside Allowlist:* No `package:feature_A` may import `package:feature_B` unless defined in `_allowedCrossFeatureImports`.
  2. *Pubspec Dependency Alignment:* No feature may declare another feature in `pubspec.yaml` unless allowlisted.
  3. *No Stale Allowlist Entries:* Every entry in `_allowedCrossFeatureImports` must correspond to an actual import in code.
  4. *No Cross-Package Private `src/` Imports:* Scans all `.dart` files in `packages/`, root `lib/`, `test/`, and `integration_test/`. Rejects any `package:<pkg>/src/...` import where `<pkg>` is not the owning package.
  5. *Relative Import Containment:* Rejects relative imports that navigate above the package's `lib/` directory (`../..`).
- **Remediation:**
  - If sharing state/domain logic: extract the interface to `packages/shared_contracts`.
  - If sharing UI: extract to `packages/shared_ui` or `packages/app_ui`.
  - If an import is private: use the target package's public barrel `lib/<target>.dart`.

---

### 2.2 `package_layering_test.dart`
- **Purpose:** Enforces the layered architecture DAG (Directed Acyclic Graph) across all workspace packages.
- **Rules Enforced:**
  1. *Layer Rank Ordering:* A package at Layer $N$ may only depend on packages at Layer $< N$. Downward dependencies only.
  2. *Package Category Matrix:* Packages must belong to one of 7 categories (`applicationShell`, `feature`, `sharedDomainContracts`, `uiDesignSystem`, `infrastructureService`, `platformIntegration`, `devTestUtilities`). Dependencies must match `_allowedCategoryDependencies`.
  3. *Cycle Detection:* DFS detects 2-node, 3-node, or $N$-node dependency cycles.
  4. *Shell Dependency Prohibition:* No workspace package may depend on `flutter_starter_template` (root app shell).
  5. *Test Utilities Isolation:* `test_utils` is categorized as `devTestUtilities` and is forbidden in runtime `dependencies:`.
- **Remediation:**
  - If a lower-layer package needs behavior from a higher layer: invert the dependency using an abstract interface at the lower layer.

---

### 2.3 `public_api_contracts_test.dart`
- **Purpose:** Enforces public API boundaries and prevents leaking internals or raw SDKs.
- **Rules Enforced:**
  1. *Single Public Barrel:* Every workspace package must have exactly one top-level file in `lib/`: `lib/<package_name>.dart`. (Allowed exceptions: `database/lib/objectbox.g.dart`, `localization/lib/l10n/`).
  2. *No Internal Exports:* Barrels must never export `src/di.dart` or `src/locator.dart`.
  3. *Feature Barrel Restrictions:* Feature packages may only export:
     - `src/di.module.dart` (micro-package module)
     - `src/presentation/**` (routes, screens, widgets, BLoCs)
     - `src/domain/entities/**` (domain entities)
     - `src/domain/services/**` (sync controllers)
     They must never export data sources, repositories, or use cases.
  4. *No Raw SDK Re-exports:* Packages must not re-export Firebase SDKs or storage libraries.
- **Remediation:**
  - Move non-barrel files into `lib/src/`.
  - Remove forbidden export lines from `lib/<package>.dart`.

---

### 2.4 `di_boundaries_test.dart`
- **Purpose:** Enforces dependency injection hygiene and isolates GetIt usage.
- **Rules Enforced:**
  1. *No Cross-Feature DI Linking:* Feature packages must never reference another feature's `Feature*PackageModule`.
  2. *Service Locator Prohibition in Core Layers:* Domain and data layers must use constructor injection; `getIt` or `locator.dart` calls are restricted to presentation and app wiring.
  3. *No Manual Registrations in Packages:* Workspace packages must not call `getIt.register*` manually; all registrations must happen through Injectable `@module` or `@LazySingleton` in `*.module.dart`.
  4. *Deterministic Module Ordering:* Root `lib/app/di/injection.dart` must register infrastructure and contracts before features.
  5. *Idempotent Reader Fallbacks:* `registerReaderFallbacks` provides null-object readers when optional features are excluded.
- **Remediation:**
  - Use `@injectable` / `@LazySingleton` instead of manual `getIt.registerLazySingleton()`.
  - Pass dependencies through constructors.

---

### 2.5 `di_module_ordering_test.dart`
- **Purpose:** Guards load-bearing runtime DI ordering constraints that static analysis cannot verify.
- **Rules Enforced:**
  - `SharedContractsPackageModule` must precede `FeatureNotificationsPackageModule` in `externalPackageModulesBefore` (because notifications resolves `ActivityNotifier` during construction).
- **Remediation:**
  - Adjust the array order in `lib/app/di/injection.dart` to satisfy the `_mustPrecede` contract.

---

### 2.6 `di_module_codegen_coverage_test.dart`
- **Purpose:** Ensures that every committed `di.module.dart` is covered by `tool/codegen.sh`.
- **Rules Enforced:**
  - For every `di.module.dart` found in the repo, its owning package directory must match one of the globs in `tool/codegen.sh`, must not be in the script's skip list, and must declare `build_runner`.
- **Remediation:**
  - Ensure any new package with DI is included in the package build loop of `tool/codegen.sh`.

---

### 2.7 `design_system_boundaries_test.dart`
- **Purpose:** Prevents design token duplication and protects design system purity.
- **Rules Enforced:**
  1. *Token Authority:* Design tokens (`AppColorPalette`, `AppTheme`, `AppTypography`, `AppSpacing`, `AppRadius`, etc.) are declared only in `packages/app_ui/lib/src`.
  2. *No Feature Coupling in app_ui:* `app_ui` must not depend on or import any `feature_*`.
  3. *No Raw Colors in app_ui Widgets:* Shared widgets in `app_ui` must not use `Color(0x...)` or `Colors.xxx`.
  4. *No Hard-Coded Copy:* Shared widgets must receive text via parameters, not embed literal strings.
- **Remediation:**
  - Reference `Theme.of(context).colorScheme` or `context.semanticColors`.
  - Pass strings from callers or localization.

---

### 2.8 `localization_and_ui_boundaries_test.dart`
- **Purpose:** Enforces that pure domain packages and layers remain completely free of UI, routing, and framework dependencies.
- **Rules Enforced:**
  - `packages/architecture/lib`, `packages/shared_contracts/lib`, `published/rev_sync/lib`, and every feature's `lib/src/domain/` must never import `flutter/material.dart`, `flutter/widgets.dart`, `localization/localization.dart`, `go_router`, or `flutter_bloc`.
- **Remediation:**
  - Remove Flutter UI imports from domain files. Represent domain errors as `Failure`, not localized strings or Widgets.

---

### 2.9 `feature_module_contracts_test.dart`
- **Purpose:** Validates the runtime feature registry (`enabledFeatures`).
- **Rules Enforced:**
  - `validateFeatureModules(enabledFeatures)` succeeds without duplicate IDs or missing prerequisites.
  - Every entry in `enabledFeatures` maps to an existing directory in `packages/features/` and has its corresponding DI module declared in `injection.dart`.
- **Remediation:**
  - Verify feature module `id` matches package directory name.

---

### 2.10 `authenticated_dio_test.dart`
- **Purpose:** Enforces network layer ownership.
- **Rules Enforced:**
  - Authenticated `Dio provideDio(...)` is owned strictly by `packages/network/lib/src/network_module.dart`.
  - No feature package may provide or register its own `Dio`.
- **Remediation:**
  - Features must inject `Dio` provided by `package:network`.

---

### 2.11 `firebase_optional_di_test.dart`
- **Purpose:** Guarantees that the app runs and resolves its core graph without Firebase credentials.
- **Rules Enforced:**
  - When `kFirebaseEnabled == false`, `AnalyticsService`, `CrashReporter`, and `PerformanceTracker` resolve to no-op implementations without throwing.
- **Remediation:**
  - Ensure adapters wrap Firebase calls in `if (kFirebaseEnabled)` or supply no-op bindings in `configureFirebaseRuntimeBindings`.

---

### 2.12 `foundation_phase01_regression_test.dart`
- **Purpose:** Prevents security regressions in Android release signing and verifies document engine assets.
- **Rules Enforced:**
  - `android/app/build.gradle.kts` release build never falls back to debug signing config.
  - Build throws `GradleException` if production keystore is missing.
  - DejaVu fonts license file exists with Bitstream Vera terms.
- **Remediation:**
  - Ensure `android/app/build.gradle.kts` uses strict keystore property checks.

---

### 2.13 `foundation_phase02_regression_test.dart`
- **Purpose:** Protects sentinel marker cleanliness and isolation.
- **Rules Enforced:**
  - `feature_document_center` is not nested inside notifications marker in `lib/app/features.dart`.
  - `feature_collections` import in `lib/app/widgets/app_shell.dart` is properly guarded by `fst:feature:collections`.
- **Remediation:**
  - Verify every feature marker pair is closed before opening another.

---

### 2.14 `foundation_phase04_ui_guardrails_test.dart`
- **Purpose:** Guards against UI color and string regressions.
- **Rules Enforced:**
  - Feature presentation code does not define raw color constants (`Colors.`, `Color(0x)`).
  - Document center has no directly embedded Text literals.
  - Bookmark detail does not reintroduce `bookmark_detail_colors.dart`.
- **Remediation:**
  - Replace raw color declarations with `Theme.of(context).colorScheme` or `context.semanticColors`.

---

### 2.15 `android_deep_link_test.dart`
- **Purpose:** Guards deep link navigation from double-firing on Android.
- **Rules Enforced:**
  - `AndroidManifest.xml` has `android:launchMode="singleTop"`.
  - `flutter_deeplinking_enabled` is set to `true`.
  - Exactly one `ACTION_VIEW` intent filter is declared.
- **Remediation:**
  - Remove duplicate `android.intent.action.VIEW` intent filters from `AndroidManifest.xml`.

---

### 2.16 `android_dependency_resolution_test.dart`
- **Purpose:** Guarantees reproducible Android builds and prevents build-script security holes.
- **Rules Enforced:**
  - `androidx.test:runner` is pinned to `1.7.0` (no dynamic versions like `1.2+`).
  - Google Services Gradle plugin is conditionally applied only when `google-services.json` exists.
  - Release signing config never falls back to debug keystore.
- **Remediation:**
  - Use exact version numbers in `build.gradle.kts`.

---

### 2.17 `ios_permission_strings_test.dart`
- **Purpose:** Enforces that scaffolded iOS apps have generic, branded permission copy without leftover template names.
- **Rules Enforced:**
  - Camera, microphone, and photo library usage descriptions in `Info.plist` are non-empty.
  - Descriptions do not contain template words ("bookmark", "collection").
  - Descriptions interpolate `$(APP_DISPLAY_NAME)`.
  - Keys sit inside `fst:feature:bookmarks` marker block so they are stripped when media features are excluded.
- **Remediation:**
  - Replace hardcoded feature names with generic copy referencing `$(APP_DISPLAY_NAME)`.

---

### 2.18 `release_secrets_preflight_test.dart`
- **Purpose:** Ensures CI release workflows fail fast when required secrets are missing.
- **Rules Enforced:**
  - Every `secrets.X` / `vars.X` consumed by release jobs in `.github/workflows/release.yml` is listed in that job's `required=( ... )` bash preflight array.
  - Runtime exemptions must have active guards in the workflow body.
  - Deploy jobs gate on identity variables (`ANDROID_PACKAGE_NAME_BASE`, `IOS_BUNDLE_ID_BASE`).
- **Remediation:**
  - Add newly referenced secrets to the job's `required=( ... )` array.

---

### 2.19 `objectbox_schema_integrity_test.dart`
- **Purpose:** Enforces ObjectBox schema UID baseline stability and prevents accidental UID drift, deletion, or reuse.
- **Rules Enforced:**
  - If ObjectBox is active (`packages/database` depends on `objectbox`), both `objectbox-model.json` and `objectbox.g.dart` must exist.
  - Existing entity, property, and relation UIDs must never mutate or drift from their committed baseline.
  - Schema expansions (adding new entities/properties) are allowed if and only if new UIDs are strictly unique and do not reuse retired UIDs.
  - Distinguishes intentional Drift database engine mode from accidental omission of ObjectBox schema files.
- **Remediation:**
  - If expanding schema, follow ObjectBox official migration guidelines and ensure UIDs are generated monotonically without modifying existing entity UIDs.

---

### 2.20 `feature_sentinel_integrity_test.dart`
- **Purpose:** Enforces repository-wide sentinel marker syntax, 1:1 symmetrical start/end pairing, nesting rules, and clean stripping behavior.
- **Rules Enforced:**
  - Every `// fst:<id>:start` must have a corresponding `// fst:<id>:end` marker in the same file.
  - No orphaned `:start` or `:end` markers.
  - Markers must conform to supported formats: `fst:feature:<id>`, `fst:db:<engine>`, `fst:network`, `fst:backend`, etc.
  - No unauthorized nesting of features within features (only documented sub-feature UI actions allowed).
  - Simulated feature stripping must leave balanced Dart braces, brackets, and parentheses in critical app files.
- **Remediation:**
  - Balance or remove unclosed markers; avoid nesting arbitrary feature markers.

---

### 2.21 `di_self_registration_test.dart`
- **Purpose:** Ensures all concrete data sources and repository implementations self-register with Injectable in their owning package.
- **Rules Enforced:**
  - Every non-abstract class in `lib/src/data/sources/` or `lib/src/data/repositories/` must carry a DI annotation (`@LazySingleton`, `@injectable`, `@singleton`).
  - No duplicate DI bindings for the same abstract interface across concrete classes.
  - The generated `di.module.dart` file must be up to date and in sync with declared DI annotations.
- **Remediation:**
  - Add `@LazySingleton(as: InterfaceName)` to the concrete data source or repository implementation class.

---

### 2.22 `domain_usecase_contract_test.dart`
- **Purpose:** Enforces the Domain UseCase contract across all feature packages to maintain predictability and typed error handling.
- **Rules Enforced:**
  - Every class named `*UseCase` in `packages/features/*/lib/src/domain/usecases/` must extend `UseCase<Output, Params>` or `NoParamUseCase<Output>`.
  - The `call(...)` method must return `Future<Result<Output>>` (from `packages/architecture`).
  - The `call(...)` method body must NOT throw raw exceptions; all failures must be returned as typed `Result.failure(Failure)`.
- **Remediation:**
  - Wrap domain execution in `runGuarded(() async { ... })` and return `Result<Output>`.

---

### 2.23 `lockfile_reproducibility_test.dart`
- **Purpose:** Enforces lockfile reproducibility and guarantees that workspace and CI builds cannot drift silently.
- **Rules Enforced:**
  - Root `pubspec.lock` and `published/cli/pubspec.lock` must exist and must never be ignored in `.gitignore`.
  - Every package declared under `workspace:` in `pubspec.yaml` must exist and define `resolution: workspace`.
  - All hosted packages in `pubspec.lock` must have `sha256` integrity checksums.
  - GitHub Actions CI (`.github/workflows/ci.yml`) must run `pub get` with `--enforce-lockfile` across all dependency resolution steps.
- **Remediation:**
  - Commit `pubspec.lock` after updates and always include `--enforce-lockfile` in CI workflow steps.
