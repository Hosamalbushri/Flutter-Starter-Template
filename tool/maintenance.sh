#!/usr/bin/env bash
#
# Standalone source maintenance utility: runs formatting, directive ordering,
# and automated Dart fixes across the workspace.
#
# Usage: tool/maintenance.sh [options]
#   --format        Format all Dart files in the workspace.
#   --fix           Apply automated Dart fixes (e.g., directives ordering).
#   --all           Run both fixes and formatting (default).
#   -h, --help      Show this help and exit.
#
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Prefer the FVM-pinned SDK if available
if command -v fvm >/dev/null 2>&1; then
  dart() { fvm dart "$@"; }
fi

run_format=0
run_fix=0

if [[ $# -eq 0 ]]; then
  run_format=1
  run_fix=1
else
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --format) run_format=1 ;;
      --fix) run_fix=1 ;;
      --all)
        run_format=1
        run_fix=1
        ;;
      -h | --help)
        sed -n '3,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
      *)
        echo "✖ Unknown option: $1" >&2
        echo "  Run 'tool/maintenance.sh --help' for usage." >&2
        exit 1
        ;;
    esac
    shift
  done
fi

if [[ "$run_fix" -eq 1 ]]; then
  echo "▶ maintenance: applying automated Dart fixes (directives ordering)…"
  dart fix --apply --code=directives_ordering .
  echo "✓ fixes applied"
fi

if [[ "$run_format" -eq 1 ]]; then
  echo "▶ maintenance: formatting workspace Dart sources…"
  dart format .
  echo "✓ formatting complete"
fi
