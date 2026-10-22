#!/usr/bin/env bash
set -euo pipefail

# ObjectBox's Flutter plugin bundles native libraries into applications, but
# `flutter test` on Linux runs directly in flutter_tester and does not build the
# desktop plugin. Download the matching, version-pinned C runtime into an
# isolated temporary directory and expose it only to this test process.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
objectbox_version="5.3.2"

case "$(uname -m)" in
  x86_64|amd64)
    objectbox_arch="x64"
    objectbox_sha256="6dbb5450c36dd11ee9074f16ecc61e79b45ff43c2082934601f3166b39c8a613"
    ;;
  aarch64|arm64)
    objectbox_arch="aarch64"
    objectbox_sha256="bdfbfbf4971057e11018ca6645697d8a40ebc7df56ccde63397cbb0e0609c0e8"
    ;;
  *)
    echo "Unsupported ObjectBox Linux test architecture: $(uname -m)" >&2
    exit 64
    ;;
esac

runtime_dir="$(mktemp -d)"
trap 'rm -rf "$runtime_dir"' EXIT
archive="$runtime_dir/objectbox.tar.gz"
url="https://github.com/objectbox/objectbox-c/releases/download/v${objectbox_version}/objectbox-linux-${objectbox_arch}.tar.gz"

curl --fail --location --retry 3 --output "$archive" "$url"
echo "$objectbox_sha256  $archive" | sha256sum --check --status
mkdir "$runtime_dir/extracted"
tar -xzf "$archive" -C "$runtime_dir/extracted"

library="$(find "$runtime_dir/extracted" -type f -name libobjectbox.so -print -quit)"
if [[ -z "$library" ]]; then
  echo "The verified ObjectBox archive did not contain libobjectbox.so" >&2
  exit 1
fi

library_dir="$(dirname "$library")"
export LD_LIBRARY_PATH="$library_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

cd "$repo_root/packages/database"
flutter_bin="${FLUTTER_BIN:-flutter}"
exec "$flutter_bin" test "$@"
