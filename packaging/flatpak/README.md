# Flatpak

CI (the `flatpak` job in `.github/workflows/ci.yml`) builds
`luna-media-player-<version>-<x86_64|aarch64>.flatpak` on the GNOME 51
runtime, then installs that bundle in the Flatpak builder container and runs
it: every ELF file must find its libraries inside the sandbox, and the
"Luna Media Player" window must come up under Xvfb (`test-bundle.sh`).

The manifest does not compile anything. It takes the installed tree of the
`.deb` CI built for that architecture, after
`packaging/linux-distros/bundle-libmpv.sh` added libmpv's dependency chain
(ffmpeg, libass, libplacebo, ...) from Ubuntu 24.04 under
`opt/luna-media-player/lib/mpv/`, with each library's copyright file and the
exact Ubuntu package versions in `lib/mpv/licenses/`. The runtime's own ffmpeg
has other sonames than the libmpv the app carries, so the chain has to come
with it.

Install a bundle from a release (the GNOME runtime comes from Flathub):

```sh
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user ./luna-media-player-1.0.1-x86_64.flatpak
flatpak run com.dhivalabs.luna_media_player
```

Permissions: Wayland/X11, the GPU, PulseAudio (sound), read-only `~/Music`
and `~/Videos` (the library scans `~/Music` by default and plays files by
path on every launch), and `org.freedesktop.ScreenSaver` (the screen stays on
during video). Folders and files outside those two come through the file
chooser portal.

## A Flathub submission would differ

- Flathub does not accept prebuilt trees from CI artifacts or libraries copied
  from another distribution. The `tree` source becomes the release `.deb`
  (`type: file`, `url:` + `sha256:`, unpacked with `bsdtar`), or the app is
  built from source with the Flutter SDK as a module.
- libmpv is then built from source against the runtime's ffmpeg (as
  `io.mpv.Mpv` does: libass, libplacebo, mpv with `-Dlibmpv=true`), and
  `lib/mpv/` goes away.
- `flatpak-builder-lint` must pass on the manifest and the metainfo
  (screenshots, release notes, a brand colour).
