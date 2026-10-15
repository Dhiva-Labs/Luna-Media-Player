# Changelog

All notable changes to Luna Media Player are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] — 2026-10-16

### Added

- Linux ARM64 (aarch64) support: the build, `.deb` and snap scripts build for
  the architecture of the machine they run on, and CI builds, tests and
  packages both x86-64 and ARM64, attaching the ARM64 `.deb` to each release.
- Snap packaging (`luna-media-player`, strictly confined, core24) for amd64 and
  arm64, built and smoke-run in CI.
- Debian source packaging for the Ubuntu PPA (`tool/make_ppa.sh`).

### Fixed

- The snap's `LD_LIBRARY_PATH` named the x86-64 library directories only; it
  now follows the architecture the snap is built for.
- The snap failed to start because ffmpeg's `libblas.so.3` and
  `liblapack.so.3` were not on its library path; both directories are now on
  `LD_LIBRARY_PATH`.
- Inside the snap the default library folder resolved to the snap's private
  data directory instead of the real `~/Music`.

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

[1.0.1]: https://github.com/Dhiva-Labs/Luna-Media-Player/releases/tag/v1.0.1
[1.0.0]: https://github.com/Dhiva-Labs/Luna-Media-Player/releases/tag/v1.0.0
