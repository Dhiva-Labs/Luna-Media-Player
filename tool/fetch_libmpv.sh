#!/usr/bin/env bash
# Fetches libmpv into third_party/mpv without needing root.
#
# media_kit's Linux plugin links against libmpv via pkg-config, and the app
# bundles libmpv.so.2 so it runs on machines that never installed mpv.
# This script downloads the Ubuntu/Debian packages, extracts them locally,
# and strips Requires.private from mpv.pc (only dynamic linking is needed,
# so the dozens of private dev dependencies are irrelevant).
#
# After running this once, build with tool/build.sh (or export the two
# PKG_CONFIG_* variables yourself and run flutter build linux).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TP="$ROOT/third_party/mpv"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if pkg-config --exists mpv 2>/dev/null; then
  echo "System libmpv found — no local copy needed."
  exit 0
fi

if [ -f "$TP/usr/lib/x86_64-linux-gnu/pkgconfig/mpv.pc" ]; then
  echo "third_party/mpv already populated."
  exit 0
fi

echo "Downloading libmpv packages…"
cd "$WORK"
apt-get download libmpv2 libmpv-dev

mkdir -p "$TP"
for deb in ./*.deb; do
  dpkg -x "$deb" "$TP"
done

# Dynamic linking needs only -I and -lmpv; the private requirements would
# demand every dev package mpv was built against. The prefix is rewritten to
# the extracted tree so plain PKG_CONFIG_PATH is enough (a sysroot would
# corrupt every other package's paths, GTK included).
PC="$TP/usr/lib/x86_64-linux-gnu/pkgconfig/mpv.pc"
sed -i '/^Requires.private:/d' "$PC"
sed -i "s|^prefix=/usr|prefix=$TP/usr|" "$PC"

echo "libmpv extracted to third_party/mpv."
