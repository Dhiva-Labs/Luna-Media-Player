#!/usr/bin/env bash
# Packages the release bundle as a .deb into dist/.
#
# The app ships its own libmpv.so.2, but that library still needs the ffmpeg/
# libass stack at runtime, so the package depends on libmpv2 — apt then pulls
# the whole chain on any Ubuntu/Debian desktop.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
PKG="luna-media-player"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# One source of truth for the version: lib/src/app_info.dart.
VERSION="${1:-$(sed -n "s/.*version = '\([^']*\)'.*/\1/p" "$ROOT/lib/src/app_info.dart")}"

# What the app claims in "Open With". Kept in step with LibraryScanner's
# extension lists.
MIME_TYPES="audio/mpeg;audio/flac;audio/ogg;audio/opus;audio/mp4;audio/aac;\
audio/x-wav;audio/x-ms-wma;audio/x-matroska;audio/aiff;audio/x-ape;\
audio/x-wavpack;audio/ac3;audio/vnd.dts;audio/amr;audio/x-musepack;\
video/mp4;video/x-matroska;video/x-msvideo;video/webm;video/quicktime;\
video/x-ms-wmv;video/mpeg;video/mp2t;video/x-flv;video/3gpp;video/3gpp2;\
video/ogg;video/x-ms-asf;video/vnd.rn-realvideo;application/vnd.rn-realmedia;"

if [ ! -x "$BUNDLE/luna_media_player" ]; then
  echo "No release bundle — run tool/build.sh first." >&2
  exit 1
fi

mkdir -p \
  "$STAGE/DEBIAN" \
  "$STAGE/opt/$PKG" \
  "$STAGE/usr/bin" \
  "$STAGE/usr/share/applications" \
  "$STAGE/usr/share/icons/hicolor/512x512/apps"

cp -r "$BUNDLE/." "$STAGE/opt/$PKG/"
ln -s "/opt/$PKG/luna_media_player" "$STAGE/usr/bin/$PKG"
cp "$ROOT/assets/icon.png" \
  "$STAGE/usr/share/icons/hicolor/512x512/apps/$PKG.png"

cat > "$STAGE/usr/share/applications/$PKG.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Luna Media Player
GenericName=Media Player
Comment=Play your music and videos, in an XP-era player
Exec=/opt/$PKG/luna_media_player %F
Icon=$PKG
Categories=AudioVideo;Audio;Video;Player;
Terminal=false
StartupWMClass=luna_media_player
MimeType=$MIME_TYPES
EOF

INSTALLED_SIZE=$(du -sk "$STAGE/opt" "$STAGE/usr" | awk '{s+=$1} END {print s}')

cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: sound
Priority: optional
Architecture: amd64
Depends: libmpv2 | libmpv1, libgtk-3-0
Installed-Size: $INSTALLED_SIZE
Maintainer: Dhivakar <dhivakar1010@gmail.com>
Homepage: https://github.com/Dhiva-Labs/Luna-Media-Player
Description: XP-era music and video player for the Linux desktop
 Luna Media Player plays the music and video already on your machine,
 wrapped in the look of the desktop players of 2004: a library, a
 playlist pane, and eight flowing visualisations.
 .
 Built with Flutter; playback by libmpv, so it opens essentially any
 format your system can decode.
EOF

mkdir -p "$ROOT/dist"
OUT="$ROOT/dist/${PKG}_${VERSION}_amd64.deb"
dpkg-deb --build --root-owner-group "$STAGE" "$OUT" > /dev/null
echo "$OUT"
