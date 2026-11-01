#!/usr/bin/env bash
# Makes an installed tree self-contained for the AppImage and the Flatpak,
# which cannot depend on a distribution's libmpv package.
#
# usage: bundle-libmpv.sh <tree> <lib dir, relative to the tree>
#
# <lib dir> is where the app's executable finds libmpv.so.2 (its RUNPATH,
# $ORIGIN/lib for a Flutter bundle). libmpv's dependency chain (ffmpeg,
# libass, libplacebo, ...), as this Ubuntu runner resolves it, is copied into
# <lib dir>/mpv/, and RUNPATH ($ORIGIN) ties the chain together, so no
# LD_LIBRARY_PATH is needed and the host's own copies of the shared desktop
# libraries are not shadowed for the rest of the process.
#
# Left to the host: glibc and the compiler runtime, GTK 3 and the libraries
# it is built on, the X11/Wayland client libraries, the GL/GPU stack (it must
# match the host's drivers) and ALSA (it must match the host's sound setup).
# That is what every GTK desktop and the GNOME Flatpak runtime have. Every
# other library in the chain is copied, with its Debian copyright file.
#
# Needs libmpv2 installed on the runner (so ldd resolves the whole chain),
# patchelf, and dpkg (to find each library's package).
set -euo pipefail
[ $# -eq 2 ] || { echo "usage: $0 <tree> <lib dir>" >&2; exit 2; }
tree="$(cd "$1" && pwd)"
libdir="$tree/$2"
deps="$libdir/mpv"

host_lib() {
  case "$1" in
    # glibc and the compiler runtime
    ld-linux*|libc.so.*|libm.so.*|libdl.so.*|libpthread.so.*|librt.so.*|libresolv.so.*|\
    libutil.so.*|libmvec.so.*|libanl.so.*|libnss_*|libthread_db.so.*|libstdc++.so.*|libgcc_s.so.*) ;;
    # GTK 3 and what it is built on
    libgtk-3.so.*|libgdk-3.so.*|libgdk_pixbuf-2.0.so.*|libglib-2.0.so.*|libgobject-2.0.so.*|\
    libgio-2.0.so.*|libgmodule-2.0.so.*|libgthread-2.0.so.*|libpango-1.0.so.*|libpangocairo-1.0.so.*|\
    libpangoft2-1.0.so.*|libcairo.so.*|libcairo-gobject.so.*|libharfbuzz.so.*|libfreetype.so.*|\
    libfontconfig.so.*|libfribidi.so.*|libatk-1.0.so.*|libatk-bridge-2.0.so.*|libatspi.so.*|\
    libepoxy.so.*|libpixman-1.so.*|libpng16.so.*|libz.so.*|libexpat.so.*|libdbus-1.so.*|libffi.so.*|\
    libmount.so.*|libblkid.so.*|libselinux.so.*|libpcre2-8.so.*) ;;
    # X11 and Wayland client libraries
    libX11.so.*|libX11-xcb.so.*|libxcb.so.*|libxcb-render.so.*|libxcb-shm.so.*|libXau.so.*|\
    libXext.so.*|libXrender.so.*|libXfixes.so.*|libXi.so.*|libXrandr.so.*|libXcursor.so.*|\
    libXdamage.so.*|libXcomposite.so.*|libXinerama.so.*|libwayland-client.so.*|\
    libwayland-cursor.so.*|libwayland-egl.so.*|libwayland-server.so.*|libxkbcommon.so.*) ;;
    # GL and the GPU, sound
    libGL.so.*|libGLX.so.*|libGLdispatch.so.*|libOpenGL.so.*|libEGL.so.*|libgbm.so.*|\
    libdrm.so.*|libglapi.so.*|libasound.so.*) ;;
    *) return 1 ;;
  esac
}

# The package that owns a file. Not every Ubuntu package has moved its files
# to /usr yet, so try the /lib spelling too.
pkg_of() {
  local out
  out="$(dpkg -S "$1" 2> /dev/null || dpkg -S "${1#/usr}" 2> /dev/null)" ||
    { echo "no package owns $1" >&2; return 1; }
  printf '%s\n' "$out" | head -n 1 | cut -d: -f1
}

sys_mpv="$(ldconfig -p | awk '$1 == "libmpv.so.2" { print $NF; exit }')"
[ -n "$sys_mpv" ] || { echo "libmpv.so.2 is not installed on this runner (apt-get install libmpv2)" >&2; exit 1; }
sys_mpv="$(readlink -f "$sys_mpv")"
mpv="$libdir/libmpv.so.2"
if [ ! -f "$mpv" ]; then
  # The app links the system libmpv instead of carrying its own copy.
  install -Dm644 "$sys_mpv" "$mpv"
fi

# Where each soname resolves on this runner: ldd follows the whole chain.
declare -A path=()
while read -r soname arrow target _; do
  [ "$arrow" = '=>' ] || continue
  if [ "$target" = not ]; then echo "ldd: $soname not found on this runner" >&2; exit 1; fi
  path["$soname"]="$target"
done < <(ldd "$mpv")

# Walk the NEEDED graph from libmpv, stopping at host libraries, so only what
# the chain itself needs is copied (not the host libraries' own dependencies).
mkdir -p "$deps/licenses"
declare -A seen=()
queue=("$mpv")
packages=("$(pkg_of "$sys_mpv")")
copied=0
while [ "${#queue[@]}" -gt 0 ]; do
  f="${queue[0]}"
  queue=("${queue[@]:1}")
  while read -r soname; do
    [ -n "${seen[$soname]:-}" ] && continue
    seen["$soname"]=1
    host_lib "$soname" && continue
    src="${path[$soname]:-}"
    [ -n "$src" ] || { echo "$soname (needed by $(basename "$f")) did not resolve" >&2; exit 1; }
    real="$(readlink -f "$src")"
    install -m644 "$real" "$deps/$soname"
    patchelf --set-rpath '$ORIGIN' "$deps/$soname"
    packages+=("$(pkg_of "$real")")
    queue+=("$deps/$soname")
    copied=$((copied + 1))
  done < <(objdump -p "$f" | awk '$1 == "NEEDED" { print $2 }')
done
patchelf --set-rpath '$ORIGIN/mpv' "$mpv"

# Licences of what was copied, and the exact Ubuntu package versions, so the
# matching sources can be fetched (apt-get source <package>=<version>).
mapfile -t packages < <(printf '%s\n' "${packages[@]}" | sort -u)
for pkg in "${packages[@]}"; do
  cp "/usr/share/doc/$pkg/copyright" "$deps/licenses/$pkg.copyright"
done
dpkg-query -W -f '${Package} ${Version}\n' "${packages[@]}" > "$deps/licenses/PACKAGES.txt"

echo "bundled $copied libraries from ${#packages[@]} Ubuntu packages into ${deps#"$tree"/}:"
du -sh "$deps"
cat "$deps/licenses/PACKAGES.txt"
