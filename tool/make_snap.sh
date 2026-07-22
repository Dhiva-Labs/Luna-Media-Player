#!/usr/bin/env bash
# Assemble and build the snap for Luna Media Player.
#
#   bash tool/make_snap.sh              # stage + build the .snap
#   bash tool/make_snap.sh --skip-build # reuse the existing release bundle
#   bash tool/make_snap.sh --upload     # ... then upload and release to stable
#
# Like the PPA, the snap ships the prebuilt Flutter bundle: `plugin: dump`
# over ./bundle. The base must stay core24 — the bundle links glibc 2.39.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$REPO/linux/packaging/snap"
BUNDLE="$REPO/build/linux/x64/release/bundle"
KIT="$REPO/dist/snap-kit"

BOLD=$'\e[1m'; GRN=$'\e[32m'; RED=$'\e[31m'; RST=$'\e[0m'
say(){ echo "${BOLD}${GRN}>>> $*${RST}"; }
die(){ echo "${BOLD}${RED}XXX $*${RST}" >&2; exit 1; }

SKIP_BUILD=0; UPLOAD=0
for a in "$@"; do case "$a" in
  --skip-build) SKIP_BUILD=1 ;;
  --upload) UPLOAD=1 ;;
  *) die "unknown flag: $a" ;;
esac; done

VER=$(sed -n "s/.*version = '\([^']*\)'.*/\1/p" "$REPO/lib/src/app_info.dart")
[ -n "$VER" ] || die "could not read the version from lib/src/app_info.dart"
say "Release version: $VER"

if [ "$SKIP_BUILD" = 0 ]; then
  say "Building the Flutter Linux release bundle..."
  "$REPO/tool/build.sh" || die "build failed"
fi
for so in libflutter_linux_gtk.so libapp.so libmpv.so.2; do
  [ -f "$BUNDLE/lib/$so" ] || die "the bundle is missing lib/$so ($BUNDLE)"
done

say "Assembling the snap kit..."
rm -rf "$KIT"
mkdir -p "$KIT/snap" "$KIT/bundle"
sed "s/^version: .*/version: '$VER'/" "$PKG/snapcraft.yaml" > "$KIT/snap/snapcraft.yaml"
cp -a "$PKG/gui" "$KIT/snap/gui"
cp -a "$BUNDLE/." "$KIT/bundle/"

say "Building the snap (LXD, several minutes)..."
(cd "$KIT" && snapcraft --use-lxd) || die "snapcraft build failed"

SNAP=$(ls "$KIT"/luna-media-player_*_amd64.snap 2>/dev/null | head -1)
[ -n "$SNAP" ] || die "no .snap produced in $KIT"
say "Built: $SNAP"

if [ "$UPLOAD" = 0 ]; then
  say "Next: bash tool/make_snap.sh --skip-build --upload"
  exit 0
fi

say "Uploading to the Snap Store..."
snapcraft upload --release=stable "$SNAP" || die "snapcraft upload failed"
say "Published. Install with: sudo snap install luna-media-player"
