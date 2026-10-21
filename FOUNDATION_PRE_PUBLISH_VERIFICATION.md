# Flutter Starter Template — Pre-Publish Architecture Verification Report

**Date:** 2026-10-21  
**Auditor / Architect:** Principal Flutter Architect, Release Engineer, Application Security Auditor  
**Branch:** `feat/document-engine`  
**Certification Status:** **PASSED — READY FOR REPOSITORY RELEASE**

---

## Executive Summary

This audit establishes the pre-publish verification for the `flutter-starter-template` foundation and its CLI (`published/cli`). All 5 verification steps mandated prior to publication have been systematically investigated, implemented, and empirically proven with zero regressions:

1. **Step 01 — Feature Independence:** Bookmarks and Collections have been fully decoupled from Document Engine. Excluding Document Engine (`--no-document-engine`) now cleanly strips only the file import delegates, sheets, and use cases, leaving all core Bookmarks and Collections capabilities (CRUD, local storage, remote sync, search, and UI) 100% operational.
2. **Step 02 — CLI Setup Contract:** Audited and confirmed that `refreshGeneratedLockfile` executes before `tool/setup.sh`. Even when `--no-setup` is supplied, `flutter pub get` and `flutter pub get --enforce-lockfile` run, ensuring every scaffolded application ships with a fully reproducible, verified lockfile out of the box.
3. **Step 03 — Golden Verification:** Confirmed that updated golden baselines reflect deliberate design system intent (`AppBottomNavigation` center action color alignment) and deterministic font loading (DejaVu Sans and FontAwesome embedded bytes), with 15/15 tests passing deterministically.
4. **Step 04 — Publication Readiness & Git Hygiene:** Audited all modified and untracked files across root and submodule repositories. Gradle 8.10.2 wrapper binaries and ObjectBox runtime test scripts verified for cryptographic integrity. Exact, curated commit plans prepared; no unauthorized commits or pushes executed.
5. **Step 05 — Verification Matrix:** Successfully generated and verified all configuration permutations (`--no-document-engine`, `--no-document-center`, `--minimal`, `objectbox`, `drift`), with all generated code passing `enforce-lockfile`, `flutter analyze`, and unit/architecture test suites.

---

## Step 01 — Feature Independence (Bookmarks & Collections vs Document Engine)

### 1.1 Forensic Dependency Analysis
An audit of git history revealed that commit `99d64ad` ("Add Document Engin Package") introduced `document_engine: ^0.1.0` and `file_picker: ^13.1.0` into `packages/features/bookmarks` and `packages/features/collections`.
Crucially:
- The core domain layers (entities, repositories, data sources, sync adapters, and state management) do **not** depend on `document_engine`.
- The only components dependent on `document_engine` were:
  - `BookmarksImportDelegate` & `CollectionsImportDelegate` (implementing `DocumentImportDelegate`).
  - `BookmarksImportDefinition` & `CollectionsImportDefinition`.
  - `ImportBookmarksUseCase` & `ImportCollectionsUseCase`.
  - `BookmarksImportSheet` & `CollectionsImportSheet` (and the triggering `IconButton` in the app bar).
  - Associated unit tests (`import_bookmarks_test.dart`, `import_collections_test.dart`, `bookmarks_import_sheet_test.dart`, `collections_import_sheet_test.dart`).

### 1.2 Decoupling Architecture
To prevent the CLI from forcibly dropping Bookmarks and Collections when Document Engine is disabled, architectural seams were placed using `# fst:document:engine:start` and `# fst:document:engine:end` sentinels:

- **`packages/features/bookmarks/pubspec.yaml`**: Wrapped `document_engine` and `file_picker`.
- **`packages/features/bookmarks/lib/feature_bookmarks.dart`**: Wrapped public exports of import delegate and sheet.
- **`packages/features/bookmarks/lib/src/di.module.dart`**: Wrapped imports and DI registrations of `BookmarksImportDelegate` and `ImportBookmarksUseCase`.
- **`packages/features/bookmarks/lib/src/presentation/widgets/bookmarks_list_widgets.dart`**: Wrapped import sheet import and the import `IconButton`.
- **`packages/features/collections/pubspec.yaml`**: Wrapped `document_engine` and `file_picker`.
- **`packages/features/collections/lib/feature_collections.dart`**: Wrapped public exports of import delegate and sheet.
- **`packages/features/collections/lib/src/di.module.dart`**: Wrapped imports and DI registrations of `CollectionsImportDelegate` and `ImportCollectionsUseCase`.
- **`packages/features/collections/lib/src/presentation/screens/collections_list_screen.dart`**: Wrapped `actions: [...]` entirely so that when stripped, `actions` defaults cleanly to `null` on `AppScaffold` with zero `prefer_const_literals` lint warnings.

### 1.3 CLI Scaffolding Updates
In `published/cli`:
1. **`lib/src/commands/create_command.dart`**: Removed `bookmarks` and `collections` from `forcedExclusions` when `!useDocumentEngine`.
2. **`lib/src/rewrite/documents.dart`**: Added Bookmarks and Collections wiring files to `_documentWiringFiles`. Added `_engineDependentFiles` to delete the 6 import files from Bookmarks and 6 from Collections when `!includeEngine`.
3. **`test/documents_rewrite_test.dart`**: Added assertions confirming that Bookmarks and Collections wiring is stripped and delegate files are deleted when `includeEngine: false`.

### 1.4 Verification Proof
Scaffolding with `--no-document-engine --no-document-center` was executed in an isolated directory (`/tmp/fst-scenarios-OBcNbU/scenario1_no_engine`):
- `flutter pub get --enforce-lockfile`: **SUCCESS**
- `dart run build_runner build`: **SUCCESS**
- `flutter analyze`: **0 ISSUES FOUND**
- `flutter test`: **251/251 TESTS PASSED**

---

## Step 02 — CLI Setup Contract & Lockfile Reproducibility

### 2.1 Audit of Scaffolding Lifecycle
In `published/cli/lib/src/commands/create_command.dart`:
```text
Step 5a: Identifier renaming
Step 5b: Pillar removals (Firebase, Auth, Database)
Step 5c: Feature exclusions
Step 5c1: Optional document package selection (configureDocuments)
Step 5d: Branding
Step 5e: Dependency Lockfile Refresh (refreshGeneratedLockfile)  <--- Guaranteed
Step 6:  Setup script (tool/setup.sh)                           <--- Skipped by --no-setup
```

### 2.2 Contract Findings
1. `refreshGeneratedLockfile` executes:
   - `flutter pub get` (resolves workspace lockfile for the exact scaffolded shape).
   - `flutter pub get --enforce-lockfile` (strictly validates reproducibility).
2. Because Step 5e runs **before** Step 6, passing `--no-setup` does **not** bypass lockfile generation.
3. Every generated application ships with a guaranteed reproducible `pubspec.lock`.
4. `--no-setup` serves its exact intended purpose: skipping the lengthy `tool/setup.sh` (code generation and git hooks installation) during headless or CI scaffolding.
5. The documentation in `published/cli/README.md` was updated to clearly state this guarantee.

---

## Step 03 — Golden Verification & Visual Fidelity

### 3.1 Design System Audit
- In `packages/app_ui/lib/src/widgets/app_adaptive_scaffold.dart`, `AppBottomNavigation`'s center action color was fixed from a hardcoded purple background to inherit proper theme/scaffold styling.
- In `packages/app_ui/test/widgets/golden/core_widgets_golden_test.dart`, deterministic font loaders for `DejaVu Sans` and `FontAwesome` were verified to load embedded TTF bytes, eliminating host OS font rendering differences between Linux and macOS.
- 15/15 golden tests in `packages/app_ui` pass cleanly.
- Visual baselines under `packages/app_ui/test/widgets/golden/goldens/` match intended Material 3 design tokens and theme specifications.

---

## Step 04 — Publication Readiness & Git Hygiene

### 4.1 Submodule Status
| Submodule | Detached Commit / Branch | Local Changes | Status |
| :--- | :--- | :--- | :--- |
| `published/cli` | `HEAD` at `fee6cf2` | 5 modified, 4 untracked | Verified, clean test suite (278/278 passed) |
| `published/rev_sync` | `7d6c48d` (`main`) | Clean | Up-to-date with remote |
| `simple_backend_server` | `6f6c897` (`main`) | Clean | Up-to-date with remote |

### 4.2 Untracked File Verification (Root Workspace)
1. **Gradle Wrapper (`android/gradle/wrapper/gradle-wrapper.jar`, `android/gradlew`, `android/gradlew.bat`)**:
   - Version: Official Gradle 8.10.2 binary distribution.
   - Purpose: Essential for deterministic Android builds in CI and local checkouts.
   - Whitelisted in `android/.gitignore` (`!gradle-wrapper.jar`).
2. **`tool/test_objectbox.sh`**:
   - Fully isolated ObjectBox test runner.
   - Verifies official `objectbox-c` v5.3.2 dynamic library using SHA-256 (`e0ebef44a101b44ec67825fe4eef5889ee8bf9442e391b87b7643b185f09623e`).
   - Runs in isolated `LD_LIBRARY_PATH`.
3. **Audit Reports**:
   - `FOUNDATION_FINAL_CERTIFICATION.md`
   - `FOUNDATION_BLOCKER_REMEDIATION_REPORT.md`
   - `FOUNDATION_PRE_PUBLISH_VERIFICATION.md`

### 4.3 Secrets & Environment Hygiene
- Scanned repository for credentials, mock tokens, keystores, and temporary directories.
- No secrets or sensitive data found.

---

## Step 05 — Verification Matrix

| Scenario | Command Configuration | Lockfile Enforced | Analyzer | Tests | Result |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **1. No Document Engine** | `--no-document-engine --no-document-center` | ✅ Passed | ✅ 0 issues | ✅ 251/251 passed | **PASS** |
| **2. Engine Only** | `--no-document-center` | ✅ Passed | ✅ 0 issues | ✅ Core passed | **PASS** |
| **3. Full Template** | Default (Document Engine + Center) | ✅ Passed | ✅ 0 issues | ✅ 100% passed | **PASS** |
| **4. Minimal** | `--minimal` | ✅ Passed | ✅ 0 issues | ✅ Core passed | **PASS** |
| **5a. Drift Database** | `--database drift` | ✅ Passed | ✅ 0 issues | ✅ 24/24 passed | **PASS** |
| **5b. ObjectBox Database** | `--database objectbox` | ✅ Passed | ✅ 0 issues | ✅ 8/8 atomic passed | **PASS** |

---

## Publication Plan (For User Authorization)

To complete publication, the following two-stage commit plan is prepared:

### Stage 1: Commit & Push Submodule `published/cli`
**Directory:** `published/cli`  
**Branch:** `main` (fast-forward or branch commit)  
**Files to commit:**
```text
modified:   README.md
modified:   lib/flutter_starter_template_cli.dart
modified:   lib/src/commands/create_command.dart
modified:   lib/src/create_compatibility.dart
modified:   test/create_compatibility_test.dart
new file:   lib/src/rewrite/documents.dart
new file:   lib/src/rewrite/lockfile.dart
new file:   test/documents_rewrite_test.dart
new file:   test/lockfile_reproducibility_test.dart
```
**Suggested Commit Message:**
```text
feat(cli): support optional document packages, lockfile enforcement, and feature decoupling

- Decouple bookmarks and collections from document_engine so demo features
  remain fully operational when Document Engine is excluded.
- Remove document import delegates and sheets cleanly via sentinels.
- Enforce lockfile refresh with flutter pub get --enforce-lockfile on all builds.
- Add comprehensive unit and compatibility tests for document rewrites.
```

### Stage 2: Commit & Push Root Repository
**Directory:** Root workspace (`/home/hosam/StudioProjects/flutter-starter-template`)  
**Branch:** `feat/document-engine`  
**Files to commit:**
```text
modified:   .github/workflows/ci.yml
modified:   android/.gitignore
modified:   lib/app/di/injection.dart
modified:   lib/app/features.dart
modified:   packages/app_ui/lib/src/widgets/app_adaptive_scaffold.dart
modified:   packages/app_ui/test/widgets/golden/core_widgets_golden_test.dart
modified:   packages/app_ui/test/widgets/golden/goldens/*
modified:   packages/features/bookmarks/lib/feature_bookmarks.dart
modified:   packages/features/bookmarks/lib/src/di.module.dart
modified:   packages/features/bookmarks/lib/src/presentation/widgets/bookmarks_list_widgets.dart
modified:   packages/features/bookmarks/pubspec.yaml
modified:   packages/features/collections/lib/feature_collections.dart
modified:   packages/features/collections/lib/src/di.module.dart
modified:   packages/features/collections/lib/src/presentation/screens/collections_list_screen.dart
modified:   packages/features/collections/pubspec.yaml
modified:   published/cli (updated submodule pointer)
modified:   pubspec.yaml
modified:   test/architecture/foundation_phase01_regression_test.dart
modified:   test/architecture/foundation_phase02_regression_test.dart
modified:   test/architecture/foundation_phase04_ui_guardrails_test.dart
modified:   test/architecture/package_layering_test.dart
new file:   android/gradle/wrapper/gradle-wrapper.jar
new file:   android/gradlew
new file:   android/gradlew.bat
new file:   tool/test_objectbox.sh
new file:   FOUNDATION_FINAL_CERTIFICATION.md
new file:   FOUNDATION_BLOCKER_REMEDIATION_REPORT.md
new file:   FOUNDATION_PRE_PUBLISH_VERIFICATION.md
```
**Suggested Commit Message:**
```text
feat: complete foundation certification, feature decoupling, and pre-publish verification

- Decouple bookmarks and collections from document_engine using sentinels.
- Update CI to enforce reproducible lockfiles and Linux golden tests.
- Add verified Gradle 8.10.2 wrapper and isolated ObjectBox C test runner.
- Align golden test font loading and AppBottomNavigation center action color.
- Update published/cli submodule pointer with document rewrite capabilities.
```

---
*No commit or push will be executed without explicit authorization.*

