# Phase 10 release-readiness report

Verified on 2026-10-15. This report describes the working tree that was tested;
it does not claim that the uncommitted changes have been released, tagged, or
published.

## Baseline

- Main repository: `48a586c02674e7180d09c99b28de6c2e9405695f`, branch
  `main`, one commit ahead of `origin/main`, with pre-existing uncommitted
  changes preserved.
- CLI submodule: `cb9d34d7639ab2e8d21b1b1e7e01815f52721d16`, detached
  HEAD, with uncommitted Phase 10 changes preserved.
- Flutter: 3.44.4 stable; pinned compatibility target: 3.44.0.
- Dart: 3.12.2; root constraint: `^3.12.0`; standalone CLI constraint:
  `>=3.4.0 <4.0.0`.
- Android: SDK 37.0.0, build-tools 37.0.0, NDK 28.2.13676358 and
  30.0.15729638 installed, AGP 8.9.1, Gradle 9.6.1, Kotlin plugin 2.4.10.
  Flutter uses Android Studio JDK 17; the shell's default JDK is 25.0.5-ea.
- Workspace: 15 reusable packages plus seven feature packages in the full
  template. The reusable packages are `analytics`, `app_platform`, `app_ui`,
  `architecture`, `config`, `database`, `database_drift`, `localization`,
  `network`, `shared_contracts`, `shared_ui`, `storage`,
  `sync_connectivity_plus`, `test_utils`, and `theme`.
- CLI commands: `create`, `create-package`, `add-feature`, `list-features`,
  `list-packages`, `remove-feature`, `remove-package`, `validate-features`, and
  `validate-package`.
- Template, feature ownership, and package ownership schemas are all version 1.
- CI workflows: `ci.yml`, `codeql.yml`, and `release.yml`.

## Compatibility and generated-application coverage

The supported and rejected flag combinations are the release contract in
[`compatibility.md`](compatibility.md). Unsupported combinations are checked
before an output directory is created and have negative CLI regression tests.

The following local-template scenarios were generated in isolated temporary
directories with `--no-setup` and passed structural checks:

| Scenario | Relevant options | Result |
|---|---|---|
| Minimal offline | `--minimal` / ObjectBox | Passed |
| Backend | `--backend --no-auth --database objectbox` | Passed |
| Firebase authentication | `--firebase --backend --auth --auth-provider firebase` | Passed |
| Firebase disabled | `--no-firebase --backend --auth --auth-provider jwt` | Passed |
| Drift database | `--no-firebase --backend --no-auth --database drift` | Passed |
| Optional exclusions | notifications and bookmarks excluded | Passed |
| Multiple-feature base | no Firebase/auth; all optional demos excluded | Passed |
| Standalone-package base | `--minimal --database drift` | Passed |

The multiple-feature fixture was then bootstrapped with dependency resolution
and workspace code generation. Three reusable packages (contracts,
infrastructure, and UI) and three features (presentation, local, and API) were
generated. Package and feature validation passed twice without changing the
source-tree hash. An independent UI package and an independent local feature
were each removed, fully validated, recreated, regenerated, analyzed, and
tested. The final generated fixture passed analysis and 86 tests.

## Transaction, startup, navigation, and UI evidence

- CLI tests inject dependency-resolution, code-generation, analyzer, and test
  failures and verify byte-for-byte rollback. Invalid ownership, modified or
  unknown files, protected packages, and direct/transitive consumers are
  rejected before deletion.
- A real lifecycle run exposed a root-only code-generation defect. Removal now
  invokes the workspace code-generation authority so pending feature package DI
  modules exist before the application graph is rebuilt. Regression tests cover
  both package and feature removal command plans.
- Transactions remain process-local. SIGKILL, host failure, or power loss can
  interrupt restoration; this is rollback-safe for handled failures, not a
  crash-safe filesystem transaction.
- Feature initialization is awaited in registry order before routing and sync
  become active. Failures retain their stack trace, identify the feature, stop
  subsequent initialization, and render the bootstrap error application.
- Root tests cover cold-start redirects, warm links, nested back behavior,
  unknown routes, auth redirects, optional features, route/name uniqueness,
  and deterministic initialization failures.
- Localization and UI tests cover English, Arabic, and Vietnamese catalog
  parity; RTL/LTR; locale persistence; light/dark theme state; responsive
  widths; high text scaling; semantics; design-system boundaries; and the ban
  on new hard-coded feature UI strings.

## Android acceptance

The default debug/dev build originally failed because the template applied the
Google Services plugin when the git-ignored `google-services.json` was absent.
Firebase build plugins are now conditional on that file. Release CI still
materializes the real file before its build.

| Acceptance item | Command/evidence | Result |
|---|---|---|
| Multi-architecture APK | `flutter build apk --debug --flavor dev` | Passed |
| ARM64 | `--target-platform android-arm64` | Passed |
| x86_64 | `--target-platform android-x64` | Passed |
| armeabi-v7a | `--target-platform android-arm` | Passed |
| Fat APK contents | `libflutter.so` present under all three ABI directories | Passed |
| Real device | Installed/launched on SM G986U, Android 13/API 33 | Passed |

The placeholder Firebase configuration permits offline template startup but
causes native Firebase SDK warnings about an invalid API key. Real Firebase
behavior still requires project-specific configuration. Flutter also warns
that AGP 8.9.1 will soon be unsupported (8.11.1 is the announced future floor)
and that several third-party plugins still apply the legacy Kotlin Gradle
plugin. These are release follow-ups, not failures on Flutter 3.44.4. Android
licenses are not fully accepted on this workstation, although all acceptance
builds completed without artifact-download blockers.

## Verification and release decision

- Root `flutter analyze --fatal-infos`: passed.
- Root `flutter test`: 110 tests passed on the finished diff.
- CLI `dart analyze --fatal-infos`: passed.
- CLI full suite: 266 tests passed on the finished diff.
- Generated lifecycle fixture: analysis passed; 86 tests passed.
- CI now has bounded job/step timeouts, direct CLI quality gates, generated-app
  smoke/analyze matrices, lifecycle recreation coverage, Android diagnostics,
  and seven-day diagnostic/coverage artifact retention.

Release status: **ready with documented follow-ups**. The local release gates
passed; CI must still pass on the eventual pushed revision before tagging or
publishing. Track the AGP/Kotlin migration warnings for the next supported
Flutter upgrade; they do not justify an untested dependency jump in this
stabilization release.
