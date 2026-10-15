#!/usr/bin/env bash
# Installs the release bundle for the current user (no root):
#   ~/.local/opt/luna_media_player      the app
#   ~/.local/share/applications         the launcher entry
#   ~/.local/share/icons                the icon
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=tool/arch.sh
. "$ROOT/tool/arch.sh"
BUNDLE="$ROOT/build/linux/$FLUTTER_ARCH/release/bundle"
DEST="$HOME/.local/opt/luna_media_player"

if [ ! -x "$BUNDLE/luna_media_player" ]; then
  echo "No release bundle found — run tool/build.sh first." >&2
  exit 1
fi

mkdir -p "$DEST" "$HOME/.local/share/applications" \
  "$HOME/.local/share/icons/hicolor/512x512/apps"

rm -rf "$DEST"
cp -r "$BUNDLE" "$DEST"
cp "$ROOT/assets/icon.png" \
  "$HOME/.local/share/icons/hicolor/512x512/apps/luna-media-player.png"

cat > "$HOME/.local/share/applications/luna-media-player.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Luna Media Player
GenericName=Media Player
Comment=Play your music and videos, in an XP-era player
Exec=$DEST/luna_media_player %F
Icon=luna-media-player
Categories=AudioVideo;Audio;Video;Player;
Terminal=false
StartupWMClass=luna_media_player
MimeType=audio/mpeg;audio/flac;audio/ogg;audio/mp4;audio/x-wav;video/mp4;video/x-matroska;video/webm;
EOF

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
echo "Installed. Find 'Luna Media Player' in your app grid."
