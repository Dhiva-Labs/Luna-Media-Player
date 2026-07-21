# Luna Media Player

An XP-era music and video player for Ubuntu and other Linux desktops, built
with Flutter. It plays the media already on your machine — no accounts, no
streaming. Named after Luna, the Windows XP theme whose look it borrows.

The chrome is modelled directly on a WMP 10 screenshot: pale Luna-blue title
bar with the navy caption glyphs, the feature taskbar where the active tab
stands up in white (Rip, Burn, Sync and Guide are drawn, dimmed, because the
player would not look right without them), royal-blue toolbars and status
strips, the white library with its blue text, the light Now Playing List pane,
and the silver-glass round transport buttons with the green volume slider.

## Features

- **Now Playing** — visualisations for audio, the picture for video, with the
  track caption in gold and the queue in a side pane.
- **Eight WMP visualisations**, ported from RetroBeat and modelled on the
  originals: *Ambience*, *Alchemy* and *Plenty* (the flowing, trail-buffer
  fields WMP was known for), plus *Bars*, *Ocean Mist*, *Scope*, *Battery* and
  *Fire Storm*. Click the stage or the little arrows to switch; the choice is
  under View → Visualizations too. The signal is procedural — decoration that
  moves while music plays, as the era's players did it.
- **Library** — scans your folders (defaults to `~/Music`), reads tags with
  `audio_metadata_reader`, sorted artist → album → track. Search filters as
  you type; double-click queues what you see and plays from that row.
- **Playback** — audio *and* video via `media_kit`/libmpv: play/pause/stop,
  previous (restarts after 3 s, like the old players), next, shuffle, repeat
  off/all/one, seek, volume and mute. Space, Ctrl+←/→ and the media keys work.
- Everything you touch — folders, volume, shuffle, repeat, visualisation — is
  remembered across launches.

## Building

```sh
tool/build.sh
```

That is the whole build. If the system has no libmpv (media_kit's playback
engine), the script first runs `tool/fetch_libmpv.sh`, which downloads the
Ubuntu packages and extracts them into `third_party/mpv` — no root needed.
The library is bundled into the app, so the result runs on machines that
never installed mpv.

To install a launcher entry for the current user:

```sh
tool/install.sh
```

## Installing

Build a Debian package and install it:

```sh
tool/make_deb.sh                  # writes dist/luna-media-player_<version>_amd64.deb
sudo apt install ./dist/luna-media-player_1.0.0_amd64.deb
```

The package registers a launcher and file associations, so audio and video
files offer **Open With → Luna Media Player**. Files and folders can also be
passed straight to the binary:

```sh
luna-media-player ~/Music/album          # a folder
luna-media-player track.flac clip.mkv    # individual files
```

## Platform support

Linux (x86_64) is the supported and tested platform — the repository contains
only the `linux/` desktop runner. Windows and macOS builds are not provided.

## Licence

MIT — see [LICENSE](LICENSE). Windows, Windows XP and Windows Media Player are
trademarks of Microsoft Corporation; this project is an independent tribute,
not affiliated with or endorsed by Microsoft.

## Notes

- Snap-packaged Flutter links with its own older glibc; the runner passes
  `-Wl,--allow-shlib-undefined` so host media libraries (which reference
  newer glibc symbols) link cleanly. They resolve at runtime.
- The process must hold exactly **one** libmpv. The runner links libmpv
  itself (`--no-as-needed`), so the loader resolves the bundled copy in
  `$ORIGIN/lib` first and both the video plugin and Dart's dlopen reuse it.
  Loading a second copy (e.g. by passing an explicit path to
  `MediaKit.ensureInitialized`) makes mpv abort the moment a video render
  context is created.
- `.ts` files are admitted to the library only if they carry MPEG-TS sync
  bytes — the extension is shared with TypeScript, and one node project in a
  scanned folder would otherwise add thousands of "videos".
- `media_kit_libs_linux`'s static mimalloc build is disabled in
  `linux/CMakeLists.txt` — it breaks under snap Flutter's toolchain and
  nothing here links it.
- The visualiser is procedural, not audio-reactive: nothing on Linux offers a
  playback tap the way Android's `Visualizer` does without pulling the whole
  PipeWire capture stack into the app.
