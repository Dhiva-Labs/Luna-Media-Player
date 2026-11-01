# Luna Media Player

[![ARM64 builds](https://github.com/Dhiva-Labs/Luna-Media-Player/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Dhiva-Labs/Luna-Media-Player/actions/workflows/ci.yml)
![Linux x64 | arm64](https://img.shields.io/badge/Linux-x64%20%7C%20arm64-informational?logo=linux&logoColor=white)
![Linux: deb | rpm | Arch | AppImage | Flatpak | Snap](https://img.shields.io/badge/Linux-deb%20%7C%20rpm%20%7C%20Arch%20%7C%20AppImage%20%7C%20Flatpak%20%7C%20Snap-informational?logo=linux&logoColor=white)

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
never installed mpv. The scripts build for the machine they run on, x86-64 or
ARM64: Flutter cannot cross-compile the Linux target, so the bundle lands in
`build/linux/x64/release/bundle` on an x86-64 machine and in
`build/linux/arm64/release/bundle` on an ARM64 one.

To install a launcher entry for the current user:

```sh
tool/install.sh
```

## Installing

Build a Debian package and install it:

```sh
tool/make_deb.sh                  # writes dist/luna-media-player_<version>_<arch>.deb
sudo apt install ./dist/luna-media-player_1.0.1_amd64.deb    # x86-64
sudo apt install ./dist/luna-media-player_1.0.1_arm64.deb    # ARM64 (aarch64)
```

The Releases page carries a prebuilt `_amd64.deb` and `_arm64.deb`.

### Other distributions

From the next release on, each release also carries these, for x86-64
(`x86_64`) and ARM64 (`aarch64`). CI installs every one of them on the
distribution named and starts the player there.

| Distribution | File | Install |
|---|---|---|
| Fedora, RHEL/Rocky/Alma | `luna-media-player-<version>-1.<arch>.rpm` | `sudo dnf install ./luna-media-player-1.0.1-1.x86_64.rpm` |
| openSUSE Tumbleweed | the same `.rpm` | `sudo zypper install --allow-unsigned-rpm ./luna-media-player-1.0.1-1.x86_64.rpm` |
| Arch, Manjaro, EndeavourOS | `luna-media-player-<version>-1-<arch>.pkg.tar.zst` | `sudo pacman -U ./luna-media-player-1.0.1-1-x86_64.pkg.tar.zst` |
| Any distribution | `Luna-Media-Player-<version>-<arch>.AppImage` | `chmod +x Luna-Media-Player-1.0.1-x86_64.AppImage && ./Luna-Media-Player-1.0.1-x86_64.AppImage` |
| Any distribution with Flatpak | `luna-media-player-<version>-<arch>.flatpak` | `flatpak install --user ./luna-media-player-1.0.1-x86_64.flatpak` |

- The `.rpm` and the Arch package use the distribution's own libmpv (Fedora
  `mpv-libs`, openSUSE `libmpv2`, Arch `mpv`) and through it the
  distribution's ffmpeg. Fedora's and openSUSE's ffmpeg leave out some
  patent-encumbered codecs (H.264/HEVC video among them); install the full
  ffmpeg from RPM Fusion or Packman to play those.
- The AppImage and the Flatpak carry libmpv with Ubuntu 24.04's ffmpeg and the
  rest of its dependency chain, so they play the same formats as the `.deb`
  on any distribution. The AppImage needs GTK 3 and the usual GL and ALSA
  libraries from the system; the Flatpak needs the GNOME runtime from Flathub
  (`flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`).
- The AppImage carries libraries from Ubuntu 24.04 and needs glibc 2.39 or
  newer (Fedora 40+, openSUSE Tumbleweed, current Arch; not openSUSE Leap 15
  or RHEL 9). The `.rpm` asks for the glibc its own files use, so dnf and
  zypper refuse a system that is too old. On RHEL, Rocky and Alma, `mpv-libs`
  comes from EPEL; CI tests the `.rpm` on Fedora and openSUSE Tumbleweed.
- The `.rpm` is not signed, hence `--allow-unsigned-rpm` on openSUSE.
- An AUR recipe (`luna-media-player-bin`, PKGBUILD + .SRCINFO built from the
  release `.deb`) is attached as `luna-media-player-bin-<version>-aur.tar.gz`;
  it is not on the AUR yet.

The package registers a launcher and file associations, so audio and video
files offer **Open With → Luna Media Player**. Files and folders can also be
passed straight to the binary:

```sh
luna-media-player ~/Music/album          # a folder
luna-media-player track.flac clip.mkv    # individual files
```

## Platform support

Linux is the supported and tested platform, on x86-64 and on ARM64
(aarch64): CI builds, tests and smoke-runs the app on both. The repository
contains only the `linux/` desktop runner. Windows and macOS builds are not
provided.

## Sponsors

Dhiva Labs is an independent, self-funded lab. [Sponsorships](https://github.com/sponsors/Dhiva-Labs) help bring this project and the rest of Dhiva Labs to every platform, iPhone and Mac included.

[![Sponsor Dhiva Labs](https://img.shields.io/badge/Sponsor-Dhiva%20Labs-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/Dhiva-Labs)

Monthly sponsors at $10 and up are listed here:

<!-- sponsors -->
*Be the first: [sponsor Dhiva Labs](https://github.com/sponsors/Dhiva-Labs).*
<!-- sponsors -->

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
