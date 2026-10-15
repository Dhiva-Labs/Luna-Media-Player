#!/usr/bin/env bash
# Builds the Linux release, pointing pkg-config at the locally fetched libmpv
# when the system doesn't have one.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=tool/arch.sh
. "$ROOT/tool/arch.sh"
TP="$ROOT/third_party/mpv"

if ! pkg-config --exists mpv 2>/dev/null; then
  "$ROOT/tool/fetch_libmpv.sh"
  export PKG_CONFIG_PATH="$TP/usr/lib/$TRIPLET/pkgconfig"
fi

cd "$ROOT"
flutter build linux --release "$@"
echo
echo "Bundle: $ROOT/build/linux/$FLUTTER_ARCH/release/bundle/luna_media_player"
