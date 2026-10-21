#!/usr/bin/env bash
#
# One-shot bootstrap: takes a fresh clone of this template to a compile-ready,
# runnable state. Idempotent — safe to re-run anytime your tree needs a refresh.
#
# Features incremental execution: skips redundant pub get, code generation, and
# localization passes when inputs have not changed and generated files exist.
#
# Usage: tool/setup.sh [options]
#   --fast          Run incremental setup (default in development).
#   --full          Force full execution of pub get, codegen, and localization.
#   --verify        Check that all generated files & dependencies are up to date.
#   --dry-run       Print planned actions without modifying files or caches.
#   --format        Format all Dart source files in the repository.
#   --fix           Apply automated Dart fixes (e.g., directives ordering).
#   --maintenance   Run full source maintenance (both --fix and --format).
#   --no-hooks      Don't enable the .githooks pre-push gate (enabled by default).
#   --no-codegen    Skip build_runner entirely.
#   --no-backend    Skip fetching Go backend dependencies.
#   -h, --help      Show this help and exit.
#
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backend_dir="$repo_root/simple_backend_server"

# --- options ----------------------------------------------------------------
enable_hooks=1
run_codegen=1
setup_backend=1
force_full=0
dry_run=0
verify_mode=0
fast_mode=0
run_format=1
run_fix=0

usage() {
  sed -n '3,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-hooks) enable_hooks=0 ;;
    --no-codegen) run_codegen=0 ;;
    --no-backend) setup_backend=0 ;;
    --no-format) run_format=0 ;;
    --full) force_full=1 ;;
    --fast) fast_mode=1 ;;
    --dry-run) dry_run=1 ;;
    --verify) verify_mode=1 ;;
    --format) run_format=1 ;;
    --fix) run_fix=1 ;;
    --maintenance | --normalize)
      run_format=1
      run_fix=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "✖ Unknown option: $1" >&2
      echo "  Run 'tool/setup.sh --help' for usage." >&2
      exit 1
      ;;
  esac
  shift
done

cd "$repo_root"

# Prefer the FVM-pinned SDK (this repo pins Flutter via .fvmrc); fall back to a
# plain toolchain if FVM is not installed. Mirrors .githooks/pre-push.
if [[ -x "$repo_root/.fvm/flutter_sdk/bin/dart" ]]; then
  has_fvm=1
  dart() { "$repo_root/.fvm/flutter_sdk/bin/dart" "$@"; }
  flutter() { "$repo_root/.fvm/flutter_sdk/bin/flutter" "$@"; }
elif command -v fvm >/dev/null 2>&1; then
  has_fvm=1
  dart() { fvm dart "$@"; }
  flutter() { fvm flutter "$@"; }
else
  has_fvm=0
fi

# Dry-run or Verify handling
if [[ "$dry_run" -eq 1 ]]; then
  dart tool/setup_planner.dart --dry-run
  exit 0
fi

if [[ "$verify_mode" -eq 1 ]]; then
  dart tool/setup_planner.dart --verify
  exit $?
fi

# --- 1. preflight / doctor --------------------------------------------------
echo "▶ setup: checking required tooling…"

if ! command -v git >/dev/null 2>&1; then
  echo "✖ git not found in PATH. Install git and retry." >&2
  exit 1
fi

if ! command -v dart >/dev/null 2>&1 || ! command -v flutter >/dev/null 2>&1; then
  echo "✖ Missing required tooling: dart/flutter not found in PATH." >&2
  echo "  Install FVM (recommended — https://fvm.app) or the Flutter SDK," >&2
  echo "  then retry. This template pins Flutter $(cat .fvmrc | grep -o '[0-9.]*') via .fvmrc." >&2
  exit 1
fi

if [[ "$has_fvm" -eq 0 ]]; then
  echo "  ⚠ fvm not found — using the Flutter SDK on PATH. Versions may differ" >&2
  echo "    from the pinned .fvmrc ($(cat .fvmrc | grep -o '[0-9.]*'))." >&2
fi

if ! command -v go >/dev/null 2>&1; then
  echo "  ⚠ go not found — the companion backend won't run until Go is installed." >&2
fi
if ! command -v node >/dev/null 2>&1; then
  echo "  ⚠ node not found — only needed for the optional firebase MCP server." >&2
fi
echo "✓ tooling OK"

# --- 2. submodules ----------------------------------------------------------
echo "▶ setup: syncing git submodules (backend)…"
git submodule update --init --recursive
echo "✓ submodules ready"

# --- 3. FVM SDK -------------------------------------------------------------
if [[ "$has_fvm" -eq 1 ]]; then
  if [[ ! -d "$repo_root/.fvm/flutter_sdk" ]]; then
    echo "▶ setup: installing the pinned Flutter SDK (fvm install)…"
    fvm install
    echo "✓ Flutter SDK installed"
  else
    echo "✓ Flutter SDK already installed (.fvm/flutter_sdk)"
  fi
fi

# --- 4. iOS one-time: disable Swift Package Manager (macOS only) ------------
if [[ "$(uname)" == "Darwin" ]]; then
  echo "▶ setup: disabling Swift Package Manager (CocoaPods required on iOS)…"
  flutter config --no-enable-swift-package-manager >/dev/null
  echo "✓ SPM disabled"
fi

# --- Setup Planner (Incremental analysis) -----------------------------------
planner_args=("--plan")
if [[ "$force_full" -eq 1 ]]; then
  planner_args+=("--full")
fi

plan_json=$(dart tool/setup_planner.dart "${planner_args[@]}")

pub_get_needed=$(echo "$plan_json" | grep -o '"pub_get_needed":[^,]*' | cut -d: -f2 | tr -d ' ')
l10n_needed=$(echo "$plan_json" | grep -o '"l10n_needed":[^,]*' | cut -d: -f2 | tr -d ' ')
codegen_packages_str=$(echo "$plan_json" | sed -n 's/.*"packages_needing_codegen":\[\([^]]*\)\].*/\1/p' | tr -d '"')
drift_packages_str=$(echo "$plan_json" | sed -n 's/.*"drift_packages_needing_codegen":\[\([^]]*\)\].*/\1/p' | tr -d '"')
app_root_codegen_needed=$(echo "$plan_json" | grep -o '"app_root_codegen_needed":[^,}]*' | cut -d: -f2 | tr -d ' ')

# --- 5. dependencies --------------------------------------------------------
if [[ "$pub_get_needed" == "true" || "$force_full" -eq 1 ]]; then
  echo "▶ setup: installing Dart/Flutter dependencies (pub get)…"
  flutter pub get
  echo "✓ dependencies installed"
else
  echo "✓ dependencies up to date (skipped pub get)"
fi

# --- 5b. localization -------------------------------------------------------
if [[ "$l10n_needed" == "true" || "$force_full" -eq 1 ]]; then
  if [[ -f "$repo_root/packages/localization/l10n.yaml" ]]; then
    echo "▶ setup: generating localizations (flutter gen-l10n)…"
    (cd "$repo_root/packages/localization" && flutter gen-l10n)
    echo "✓ localizations generated"
  fi
else
  echo "✓ localizations up to date (skipped gen-l10n)"
fi

# --- 6. code generation -----------------------------------------------------
if [[ "$run_codegen" -eq 1 ]]; then
  if [[ "$force_full" -eq 1 ]]; then
    echo "▶ setup: generating code (full build_runner across workspace)…"
    ./tool/codegen.sh --full
    echo "✓ code generated"
  else
    # Build list of packages needing codegen
    packages_to_build=()
    if [[ -n "$codegen_packages_str" ]]; then
      IFS=',' read -r -a codegen_pkgs <<< "$codegen_packages_str"
      for p in "${codegen_pkgs[@]}"; do
        p_clean=$(echo "$p" | tr -d ' ')
        [[ -n "$p_clean" ]] && packages_to_build+=("$p_clean")
      done
    fi

    if [[ -n "$drift_packages_str" ]]; then
      IFS=',' read -r -a drift_pkgs <<< "$drift_packages_str"
      for p in "${drift_pkgs[@]}"; do
        p_clean=$(echo "$p" | tr -d ' ')
        [[ -n "$p_clean" ]] && packages_to_build+=("$p_clean")
      done
    fi

    if [[ "$app_root_codegen_needed" == "true" ]]; then
      packages_to_build+=(".")
    fi

    if [[ ${#packages_to_build[@]} -gt 0 ]]; then
      echo "▶ setup: incrementally generating code for ${#packages_to_build[@]} target(s): ${packages_to_build[*]}…"
      ./tool/codegen.sh "${packages_to_build[@]}"
      echo "✓ code generated"
    else
      echo "✓ code generation up to date (skipped build_runner)"
    fi
  fi
else
  echo "• skipping code generation (--no-codegen) — the tree won't compile until you run build_runner."
fi

# Commit cache manifest on successful execution
dart tool/setup_planner.dart --commit >/dev/null

# --- 7. source normalisation (opt-in) ---------------------------------------
if [[ "$run_fix" -eq 1 ]]; then
  echo "▶ setup: applying fixes (imports ordering)…"
  dart fix --apply --code=directives_ordering . >/dev/null
  echo "✓ fixes applied"
fi

if [[ "$run_format" -eq 1 ]]; then
  echo "▶ setup: formatting sources…"
  dart format . >/dev/null
  echo "✓ sources formatted"
fi

# --- 8. backend dependencies ------------------------------------------------
if [[ "$setup_backend" -eq 1 ]]; then
  if command -v go >/dev/null 2>&1 && [[ -f "$backend_dir/go.mod" ]]; then
    echo "▶ setup: fetching backend Go dependencies…"
    (cd "$backend_dir" && go mod download)
    echo "✓ backend dependencies ready"
  else
    echo "• skipping backend deps (go missing or submodule empty)."
  fi
fi

# --- 9. git hooks (opt-in, default on) --------------------------------------
if [[ "$enable_hooks" -eq 1 ]]; then
  current_hooks_path="$(git config --get core.hooksPath || true)"
  if [[ "$current_hooks_path" != ".githooks" ]]; then
    echo "▶ setup: enabling the pre-push hook (git config core.hooksPath)…"
    git config core.hooksPath .githooks
    echo "✓ pre-push hook enabled (bypass once with: git push --no-verify)"
  else
    echo "✓ pre-push hook already enabled"
  fi
fi

# --- 10. Firebase reminder ---------------------------------------------------
if [[ ! -f "$repo_root/android/app/google-services.json" ]] ||
  [[ ! -f "$repo_root/ios/Runner/GoogleService-Info.plist" ]]; then
  echo "• Firebase config is git-ignored and missing. The app builds with"
  echo "  placeholders, but for real Firebase run 'flutterfire configure' and"
  echo "  drop google-services.json / GoogleService-Info.plist into place."
fi

# --- 11. summary ------------------------------------------------------------
fvm_prefix=""
[[ "$has_fvm" -eq 1 ]] && fvm_prefix="fvm "
cat <<EOF

✓ Setup complete. Next steps:

  # start the local backend (in another terminal)
  cd simple_backend_server && go run .        # → http://localhost:8080

  # run the app
  ${fvm_prefix}flutter run

EOF
