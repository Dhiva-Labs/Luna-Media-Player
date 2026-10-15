# Sourced by the other tool/ scripts: the architecture of this machine in the
# spellings they need.
#
#   FLUTTER_ARCH  directory name under build/linux/ (x64 or arm64)
#   DEB_ARCH      Debian and snap architecture name (amd64 or arm64)
#   TRIPLET       multiarch library directory under usr/lib/
#
# Flutter cannot cross-compile the Linux desktop target, so every script works
# on the bundle that was built on the machine it runs on.
case "$(uname -m)" in
  x86_64)
    FLUTTER_ARCH=x64
    DEB_ARCH=amd64
    TRIPLET=x86_64-linux-gnu
    ;;
  aarch64 | arm64)
    FLUTTER_ARCH=arm64
    DEB_ARCH=arm64
    TRIPLET=aarch64-linux-gnu
    ;;
  *)
    echo "unsupported machine '$(uname -m)' (x86_64 or aarch64)" >&2
    exit 1
    ;;
esac
