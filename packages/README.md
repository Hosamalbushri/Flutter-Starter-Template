# Workspace packages

Reusable infrastructure for the Flutter starter template, split out of
`lib/core/` into [Dart pub workspace](https://dart.dev/tools/pub/workspaces)
members. The root app depends on these through their entry points (e.g.
`package:network/network.dart`) rather than on the third-party
packages directly, so implementation details and versions stay owned in one
place.

| Package | Category | Responsibility |
|---|---|---|
| `architecture` | Shared Domain Contracts | Pure-Dart architecture primitives (`Failure`, `Result`, `UseCase`) |
| `shared_contracts` | Shared Domain Contracts | Cross-feature *business* vocabulary (`AuthUser`, reader interfaces, the app-wide `Session` lifecycle) used by 2+ features |
| `app_ui` | UI & Design System | Design system — tokens (`AppSpacing`, `AppRadius`, `AppElevation`, `AppIconSize`, `AppDurations`, `AppBreakpoints`), generic widgets, layout, animation |
| `localization` | UI & Design System | Generated `AppLocalizations` (`en`, `vi`, `ar` LTR/RTL) and `context.l10n` extension |
| `theme` | UI & Design System | `ThemeBloc`, `AppColors` `ThemeExtension`, and persisted theme state |
| `shared_ui` | UI & Design System | Cross-feature *presentation* widgets needing Flutter — the `SessionScope` accessor + shared visuals |
| `analytics` | Infrastructure & Service | Analytics service port + Firebase adapter + route observer |
| `config` | Infrastructure & Service | Environment config + Remote Config service port |
| `database` / `database_drift` | Infrastructure & Service | Centralized local persistence (ObjectBox default or Drift alternative) |
| `network` | Infrastructure & Service | `Dio`/`Retrofit` client + auth/retry/performance interceptors |
| `rev_sync` (`published/rev_sync`) | Infrastructure & Service | Offline-first sync engine — scheduler + revision-based delta CRUD with conflict detection (pure Dart) |
| `storage` | Infrastructure & Service | `SharedPreferences` + `FlutterSecureStorage` provisioning (`AuthTokenStore`, iOS Keychain reinstall reset) |
| `app_platform` | Platform Integration | Device integrations — crash reporting port, media, notifications, permissions, share |
| `sync_connectivity_plus` | Platform Integration | `connectivity_plus` adapter implementing `ConnectivitySource` for `rev_sync` |
| `test_utils` | Dev & Testing Utilities | Shared `mocktail` export, cross-package mocks/fakes, shared fixtures, test images (`dev_dependencies` only) |

Dependency direction is `app → features → shared_contracts / shared_ui →
app_ui / localization / theme / platform / infra → architecture / rev_sync`. A
package must not depend on the root app, no package may import another
package's private `lib/src/`, and a feature must not depend on another feature
outside the documented capability allowlist (enforced by `test/architecture/`
and `fst validate-features`). See [`docs/architecture.md`](../docs/architecture.md)
for the complete package architecture, `FeatureModule`, DI, public API, and UI
contracts.

## Dependency injection — the micro-package pattern

Each package that registers `@injectable`/`@module` types carries its own DI
wiring so the app doesn't have to know its internals:

- `lib/src/di.dart` holds an empty top-level function annotated with
  `@InjectableInit.microPackage()` — the codegen anchor.
- Running `build_runner` **inside the package** generates `lib/src/di.module.dart`
  containing a `class <PackageName>PackageModule extends MicroPackageModule`
  (e.g. `analytics` → `CoreAnalyticsPackageModule`).
- The barrel exports that module class.

The app composes them in `lib/app/di/injection.dart` via
`@InjectableInit(externalPackageModulesBefore: [ExternalModule(...), ...])`.
**Order matters**: a package whose types depend on another's must be listed
after it (e.g. `network` after `config` because `NetworkModule` reads
`EnvConfig`). Build-time "depends on unregistered type" warnings for
cross-package dependencies are expected and resolve at runtime.

After changing injectable types in a package, rerun `build_runner` in that
package, then at the repo root to regenerate `injection.config.dart`.

## Conventions

- **All package-owned tests live beside their package** under
  `packages/<name>/test` — infra packages and feature packages alike. Each
  feature carries a `test/support.dart` with its own mocks/fixtures, re-exporting
  `package:test_utils/test_utils.dart` for the shared doubles
  (`FakeSession`, the `shared_contracts` reader mocks) and fixtures
  (`testUser`, `testFailure`). Only genuinely app-level suites stay in the root
  `test/` — the full-app `widget_test.dart` and the `architecture/` layering
  and feature-boundary tests.
- A type graduates from a feature into a workspace package / `shared` location only on
  the **rule of three** — when ≥2 consumers actually depend on it today.
