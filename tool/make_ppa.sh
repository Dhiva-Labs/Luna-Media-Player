#!/usr/bin/env bash
# Assemble and upload the Ubuntu PPA source package for Luna Media Player.
#
#   bash tool/make_ppa.sh              # stage only (verifies the payload)
#   bash tool/make_ppa.sh --skip-build # reuse the existing release bundle
#   bash tool/make_ppa.sh --upload     # stage + debuild -S + dput
#
# Launchpad's builders have no Flutter SDK, so the source package carries the
# prebuilt bundle and debian/rules only installs it.
#
# Regression guard: debian/source/options must ship in every kit. Without it
# dpkg-source applies its default ignore list, which silently drops *.so —
# that is what shipped a broken ApiWorkbench 1.0.0 (installed fine, then died
# with "error while loading shared libraries: libflutter_linux_gtk.so").
set -euo pipefail

KEY=0D3EFC9C8CE20ADE3CE809AD3D8D857AAF4D50E6
PPA_TARGET=ppa:dhiva-labs/apps
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$REPO/linux/packaging"
BUNDLE="$REPO/build/linux/x64/release/bundle"
OUT="$REPO/dist/ppa"

BOLD=$'\e[1m'; GRN=$'\e[32m'; RED=$'\e[31m'; RST=$'\e[0m'
say(){ echo "${BOLD}${GRN}>>> $*${RST}"; }
die(){ echo "${BOLD}${RED}XXX $*${RST}" >&2; exit 1; }

SKIP_BUILD=0; UPLOAD=0
for a in "$@"; do case "$a" in
  --skip-build) SKIP_BUILD=1 ;;
  --upload) UPLOAD=1 ;;
  *) die "unknown flag: $a" ;;
esac; done

# One source of truth for the version, as everywhere else.
VER=$(sed -n "s/.*version = '\([^']*\)'.*/\1/p" "$REPO/lib/src/app_info.dart")
[ -n "$VER" ] || die "could not read the version from lib/src/app_info.dart"
say "Release version: $VER"

CHVER=$(head -1 "$PKG/debian/changelog" | grep -oP '\(\K[^)]+') || true
[ "$CHVER" = "$VER" ] || die "debian/changelog top entry is '$CHVER', expected '$VER'.
Launchpad rejects a version it has already seen, so add a new entry to
$PKG/debian/changelog before uploading."

[ -f "$PKG/debian/source/options" ] \
  || die "linux/packaging/debian/source/options is missing — *.so files would be stripped from the source tarball"

if [ "$SKIP_BUILD" = 0 ]; then
  say "Building the Flutter Linux release bundle..."
  "$REPO/tool/build.sh" || die "build failed"
fi
for so in libflutter_linux_gtk.so libapp.so libmpv.so.2; do
  [ -f "$BUNDLE/lib/$so" ] || die "the bundle is missing lib/$so ($BUNDLE)"
done

say "Assembling the PPA source tree..."
TREE="$OUT/luna-media-player-$VER"
rm -rf "$OUT"
mkdir -p "$TREE/usr/lib/luna-media-player" \
         "$TREE/usr/share/applications" \
         "$TREE/usr/share/icons/hicolor/512x512/apps" \
         "$TREE/usr/share/icons/hicolor/256x256/apps"
cp -a "$PKG/debian" "$TREE/debian"
cp -a "$BUNDLE/." "$TREE/usr/lib/luna-media-player/"
cp "$PKG/luna-media-player.desktop" "$TREE/usr/share/applications/"
cp "$PKG/icons/luna-media-player-512.png" \
   "$TREE/usr/share/icons/hicolor/512x512/apps/luna-media-player.png"
cp "$PKG/icons/luna-media-player-256.png" \
   "$TREE/usr/share/icons/hicolor/256x256/apps/luna-media-player.png"

say "Staged OK: $TREE"

if [ "$UPLOAD" = 0 ]; then
  say "Next: bash tool/make_ppa.sh --skip-build --upload"
  exit 0
fi

say "Building the signed source package (GPG passphrase expected)..."
(cd "$TREE" && debuild -S -sa -k"$KEY") || die "debuild failed"

TARBALL="$OUT/luna-media-player_${VER}.tar.xz"
[ -f "$TARBALL" ] || die "expected tarball not found: $TARBALL"
# Listed once into a variable on purpose: piping tar into `grep -q` makes grep
# exit early, tar die of SIGPIPE, and `set -o pipefail` call the whole check a
# failure even when the file is present.
CONTENTS=$(tar tJf "$TARBALL")
for so in libflutter_linux_gtk.so libapp.so libmpv.so.2; do
  case $CONTENTS in
    *"/lib/$so"*) ;;
    *) die "SAFETY STOP: $TARBALL does not contain $so — refusing to upload a broken package" ;;
  esac
done
say "Tarball verified: the bundled libraries are present."

(cd "$OUT" && dput "$PPA_TARGET" "luna-media-player_${VER}_source.changes") \
  || die "dput failed"
say "Uploaded to $PPA_TARGET — watch for the Launchpad build email."
say "Once published: sudo add-apt-repository ppa:dhiva-labs/apps && sudo apt install luna-media-player"
