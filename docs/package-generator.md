# Reusable Package Generator

`fst create-package` creates standalone workspace packages without changing the
feature lifecycle. Features continue to use `fst add-feature`.

## Package Types

| Type | Runtime | Category | Intended contents |
|---|---|---|---|
| `contracts` | Dart | Shared domain contracts | Pure interfaces and values; no Flutter/UI imports |
| `infrastructure` | Dart | Infrastructure/service | Reusable technical service boundaries |
| `platform` | Flutter | Platform integration | Device/plugin-facing public values and adapters |
| `ui` | Flutter | UI/design system | Business-neutral reusable widgets using existing tokens |
| `dev` | Dart | Development/testing | Fixtures and developer-only helpers |

Every package has `lib/<name>.dart`, private implementation under `lib/src/`,
at least one test, `resolution: workspace`, and `.fst-package.json`. The
manifest records generator ownership, type, dependencies, and initially owned
files. Source files remain user-maintained; the manifest is not a cache of the
live dependency graph and does not authorize deletion.

## Commands

```bash
fst create-package inventory_contracts --type contracts
fst create-package inventory_storage --type infrastructure \
  --dependency inventory_contracts
fst create-package inventory_ui --type ui \
  --dependency inventory_contracts --dependency inventory_storage
fst create-package preview_helpers --type dev --dry-run
fst validate-package inventory_ui
```

`--dependency` is repeatable and accepts only existing workspace packages.
The generator rejects application-shell, feature implementation, unknown,
category-invalid, test-utility runtime, and circular dependencies before
writing. `--dry-run` performs no writes. `--no-verify` skips `pub get`, package
analysis, and package tests; it is intended for batching packages before one
verification pass.

Generation computes all marker-based workspace/category/layer edits before
writing and takes a byte-for-byte project snapshot. An I/O, validation,
dependency-resolution, analysis, or test failure restores that snapshot. As
with feature transactions, a hard process kill or power loss cannot be
recovered by the in-memory snapshot.

## Public API And Validation

`fst validate-package` reads the live pubspec and source tree. It checks the
manifest when present, workspace membership, public entrypoint, private
imports, raw SDK leakage, contract-layer UI imports, required tests, dependency
direction, feature/shell/test-utility boundaries, and workspace cycles. Legacy
packages without a manifest are validated but are never classified as
CLI-owned.

## Local Template Contract

Local templates may declare `.fst-template.json` schema version `1`, template
kind `application`, and supported customization points. Declared incompatible
versions are rejected before copying. Templates predating the manifest retain
a structural compatibility path requiring the established workspace, feature,
DI, and architecture files. The mechanism is local and declarative: it does
not download templates or execute plugins.

## Verification Scope

Responsive UI coverage exercises compact/medium/expanded behavior immediately
around the `600` and `840` logical-pixel breakpoints. Arabic localization tests
cover ICU zero, one, two, few, many, and other plural categories. No runtime
performance benchmark was executed by these tests; performance language in
the project is architectural intent unless accompanied by separately recorded
measurements.
