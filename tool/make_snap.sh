#!/usr/bin/env bash
# Assemble and build the snap for Luna Media Player.
#
#   bash tool/make_snap.sh              # stage + build the .snap
#   bash tool/make_snap.sh --skip-build # reuse the existing release bundle
#   bash tool/make_snap.sh --kit-only   # stage dist/snap-kit, do not run snapcraft
#   bash tool/make_snap.sh --upload     # ... then upload and release to stable
#
# Like the PPA, the snap ships the prebuilt Flutter bundle: `plugin: dump`
# over ./bundle. The base must stay core24 — the bundle links glibc 2.39.
# The snap is built for the architecture of the machine this runs on (amd64 or
# arm64): Flutter does not cross-compile, so the bundle is that machine's.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=tool/arch.sh
. "$REPO/tool/arch.sh"
PKG="$REPO/linux/packaging/snap"
BUNDLE="$REPO/build/linux/$FLUTTER_ARCH/release/bundle"
KIT="$REPO/dist/snap-kit"

BOLD=$'\e[1m'; GRN=$'\e[32m'; RED=$'\e[31m'; RST=$'\e[0m'
say(){ echo "${BOLD}${GRN}>>> $*${RST}"; }
die(){ echo "${BOLD}${RED}XXX $*${RST}" >&2; exit 1; }

SKIP_BUILD=0; UPLOAD=0; KIT_ONLY=0
for a in "$@"; do case "$a" in
  --skip-build) SKIP_BUILD=1 ;;
  --kit-only) KIT_ONLY=1; SKIP_BUILD=1 ;;
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

if [ "$KIT_ONLY" = 1 ]; then
  say "Snap kit staged in $KIT"
  exit 0
fi

say "Building the snap (LXD, several minutes)..."
(cd "$KIT" && snapcraft --use-lxd) || die "snapcraft build failed"

SNAP=$(ls "$KIT"/luna-media-player_*_"$DEB_ARCH".snap 2>/dev/null | head -1)
[ -n "$SNAP" ] || die "no .snap produced in $KIT"
say "Built: $SNAP"

if [ "$UPLOAD" = 0 ]; then
  say "Next: bash tool/make_snap.sh --skip-build --upload"
  exit 0
fi

say "Uploading to the Snap Store..."
snapcraft upload --release=stable "$SNAP" || die "snapcraft upload failed"
say "Published. Install with: sudo snap install luna-media-player"
