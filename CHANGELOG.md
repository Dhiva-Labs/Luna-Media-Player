# Changelog

All notable changes to Luna Media Player are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-07-18

First release.

### Added

- XP-era player interface: title bar, menu bar, feature taskbar with the
  active tab in white, royal-blue toolbars and status strips, the white
  library, the Now Playing List pane, and the silver-glass transport with its
  green volume slider.
- Library that scans folders for audio and video, reads tags, and sorts by
  artist, album and track number. Live search; tree pane splitting All Music
  from All Video.
- Playback via `media_kit` / libmpv: play, pause, stop, previous (restarts the
  track after 3 s), next, seek, volume, mute, shuffle, and repeat off/all/one.
- Video playback on the Now Playing stage, with the library's picture window
  giving way to the video surface.
- Eight visualisations: Ambience, Alchemy, Plenty, Bars, Ocean Mist, Scope,
  Battery and Fire Storm.
- Album art and metadata display for the playing track.
- Keyboard shortcuts: Space, Ctrl+←/→, and the media keys.
- File associations and command-line arguments — files and folders open from
  the file manager or the shell.
- Debian packaging (`tool/make_deb.sh`), which bundles libmpv so the player
  runs on machines without mpv installed.

[1.0.0]: https://github.com/Dhiva-Labs/Luna-Media-Player/releases/tag/v1.0.0
