# Compatibility policy

This document is the release contract for template schema `1` and package and
feature ownership schema `1`. The repository is validated with Flutter 3.44.0
and Dart 3.12.0. The standalone `fst` CLI supports Dart `>=3.4.0 <4.0.0` and
rejects a local template whose contract is newer than it understands.

## `fst create` compatibility matrix

The database column accepts both supported engines: `objectbox` (default) and
`drift`. `--no-setup` and `--template-path` are orthogonal to every supported
row: the former skips dependency installation/code generation and the latter
selects a schema-compatible local checkout.

| Shape | Firebase | Backend | Auth | Provider | Supported | Notes |
|---|---:|---:|---:|---|---:|---|
| Full (default) | yes | yes | yes | `jwt` | yes | All demo features are enabled unless excluded. |
| Firebase Auth | yes | yes | yes | `firebase` | yes | Requires all three pillars. |
| No Firebase | no | yes | yes/no | `jwt` | yes | Firebase services use no-op adapters. |
| User-less backend | yes/no | yes | no | n/a | yes | Backend packages remain; auth UI/session are removed. |
| Local-only | yes/no | no | no | n/a | yes | Server-backed demo features are removed. |
| Local-only JWT auth | yes/no | no | yes | `jwt` | yes | Keeps the REST/JWT client but no demo sync backend. |
| Minimal | no | no | no | n/a | yes | Selected by `--minimal`; no Firebase, backend, or auth. |

Feature exclusion is supported in every non-minimal row. The selectable demo
features are `bookmarks`, `collections`, and `notifications`; excluding
`collections` also excludes its dependent `bookmarks`. Backend-disabled and
minimal shapes remove all three automatically.

The CLI rejects these combinations before acquiring or modifying a template:

- `--minimal` with an explicit positive `--firebase`, `--backend`, or `--auth`.
- An explicit `--auth-provider` when authentication is disabled.
- `--auth-provider firebase` without Firebase, backend, or authentication.
- `--api-url` when both backend and authentication are disabled.

## Upgrade and migration guidance

- Keep `.fvmrc`, CI's Flutter pin, and the documented supported Flutter version
  aligned. Validate generated applications before adopting another SDK.
- A schema version bump is required when a CLI release cannot safely interpret
  the existing template or ownership manifest. Add an explicit migration or
  fail with an upgrade instruction; never guess across schema versions.
- Ownership manifests protect user-modified files. Resolve or revert reported
  modifications before removal, or use the command's explicit force option
  only after reviewing the diff.
- Generation is reproducible from a pinned CLI version, a fixed template HEAD,
  the same flags, and the committed lockfiles. `--template-path` is the release
  verification path for testing a CLI and template together before publishing.

