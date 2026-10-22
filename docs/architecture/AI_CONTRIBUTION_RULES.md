# AI Contribution Rules & Engineering Guardrails

> **Authoritative Operating Guidelines for AI Agents and Automated Contributors**
> Targets: Antigravity, Claude Code, GitHub Copilot, Cursor, Codex, and human contributors.
> **Single Source of Truth:** This file defines the binding architectural guardrails. If `AGENTS.md` is instantiated at the workspace root, it must directly reference this document.

---

## 1. Governance Architecture: The Single Source of Truth

To prevent contradictory or stale guidance across agent runtimes:
- **`docs/architecture/AI_CONTRIBUTION_RULES.md`** (this document) is the **primary architectural authority** for repository design, boundary rules, and DI constraints.
- **`CLAUDE.md`** provides operational instructions (FVM usage, CocoaPods vs SPM configuration, commands, and formatting).
- **`AGENTS.md` (Specification):** When instantiated in the root directory for cross-agent discovery, `AGENTS.md` must not duplicate architecture rules. Instead, it must point directly to `docs/architecture/` to preserve a single source of truth:
  ```markdown
  # AGENTS.md
  See [CLAUDE.md](CLAUDE.md) for toolchain operations and [AI_CONTRIBUTION_RULES.md](docs/architecture/AI_CONTRIBUTION_RULES.md) for binding architecture contracts.
  ```

---

## 2. Inviolable Tooling & Environment Invariants

### Rule 1: Always Invoke Tooling via FVM
- **Constraint:** The project pins Flutter SDK `3.44.0` in `.fvmrc`.
- **Action:** Always run commands using `fvm flutter <cmd>` and `fvm dart <cmd>`.
- **Prohibition:** Never invoke system-level `flutter` or `dart`. It introduces version drift and fails CI.

### Rule 2: Formatting is a Non-Negotiable Gate
- **Constraint:** CI executes `dart format --set-exit-if-changed .` as a required status check.
- **Action:** Run `fvm dart format .` after any file creation or modification.
- **Prohibition:** Never submit unformatted files, multiline template strings with lines > 80 chars, or irregular blank lines left behind by comment deletions.

### Rule 3: Respect iOS CocoaPods Configuration
- **Constraint:** Flutter 3.44.0 hardcodes Swift Package Manager targets to iOS 13.0, while Firebase requires iOS 15.0.
- **Action:** SPM must be disabled globally on development environments:
  `fvm flutter config --no-enable-swift-package-manager`
  Always use CocoaPods (`cd ios && pod install`).

---

## 3. Modular Architecture & Boundary Invariants

### Rule 4: Zero Cross-Package Private `src/` Imports
- **Constraint:** Enforced by `test/architecture/feature_boundaries_test.dart`.
- **Prohibition:** Never import `package:<pkg>/src/...` unless `<pkg>` is the current owning package.
- **Action:** Always import through the public barrel: `package:<pkg>/<pkg>.dart`.

### Rule 5: Strict Relative Import Containment
- **Constraint:** Enforced by `scanDirectivesForBoundaryViolations`.
- **Prohibition:** Relative imports (`../`) must never escape the package's `lib/` directory.

### Rule 6: Respect Cross-Feature Decoupling
- **Constraint:** Feature packages (`packages/features/*`) must not import each other directly unless documented in `_allowedCrossFeatureImports`.
- **Current Allowlist:**
  - `feature_bookmarks` $\rightarrow$ `feature_collections`
  - `feature_profile` $\rightarrow$ `feature_auth`
- **Action:** If data or state must be shared across features, expose an abstract contract in `packages/shared_contracts`.

### Rule 7: Pure Domain Layer Isolation
- **Constraint:** Enforced by `test/architecture/localization_and_ui_boundaries_test.dart`.
- **Prohibition:** Domain packages (`architecture`, `shared_contracts`, `rev_sync`) and feature `domain/` layers must **NEVER** import:
  - `flutter/material.dart` or `flutter/widgets.dart`
  - `localization/localization.dart`
  - `go_router`
  - `flutter_bloc`

---

## 4. Dependency Injection & Persistence Invariants

### Rule 8: Feature Packages Must Self-Register DI
- **Constraint:** The host app's `DriftModule` or `ObjectBoxModule` provides only engine primitives (`AppDatabase`, `Store`, `AtomicWriteCoordinator`, `SyncCursorStore`).
- **Action:** Every feature must register its own data sources via `@LazySingleton(as: Interface)` in its `di.module.dart`. The host app must never wire feature data sources directly.

### Rule 9: Maintain Load-Bearing DI Registration Order
- **Constraint:** Enforced by `test/architecture/di_module_ordering_test.dart`.
- **Ordering Requirements in `lib/app/di/injection.dart`:**
  1. Infrastructure and contract modules must precede all feature modules.
  2. `StoragePackageModule` must precede `NetworkPackageModule`.
  3. `SharedContractsPackageModule` must precede `FeatureNotificationsPackageModule`.

### Rule 10: ObjectBox Schema UID Immutability
- **Constraint:** `packages/database/lib/objectbox.g.dart` holds stable schema UIDs and is tracked in git.
- **Prohibition:** Never delete or blindly regenerate `objectbox.g.dart`. Any schema change must follow the ObjectBox migration guide.

---

## 5. Sentinel Marker & CLI Invariants

### Rule 11: Perfectly Symmetrical Sentinel Blocks
- **Constraint:** Enforced by `test/architecture/foundation_phase02_regression_test.dart` and CLI rewriters.
- **Syntax:** `// fst:<marker_name>:start` ... `// fst:<marker_name>:end`.
- **Prohibitions:**
  - Never leave an unclosed `:start` marker.
  - Never nest one feature's marker inside another.
  - Never place routing primitives inside backend `_infra` markers; always use `_router`.

---

## 6. Pre-Flight Verification Checklist for AI Agents

Before an AI agent claims that any task is complete, it must execute and verify the following sequence:

```bash
# Step 1: Format codebase (must exit 0 with no diff)
fvm dart format --set-exit-if-changed .

# Step 2: Static analysis (0 errors, 0 warnings)
fvm flutter analyze

# Step 3: Architecture guardrails (all 18 suites must pass)
fvm flutter test test/architecture/

# Step 4: Verify codegen coverage
fvm flutter test test/architecture/di_module_codegen_coverage_test.dart

# Step 5: Check git status (ensure no accidental production changes or unformatted files)
git status
```
