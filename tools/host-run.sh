#!/bin/sh
# Run an unmodified macOS x86_64 Mach-O command-line tool under iosim-run.
# The host-symbol bridge resolves libc++/libarchive/libbz2/CommonCrypto imports
# from the loader process; it is off for ordinary simulator guests.
# usage: tools/host-run.sh /path/to/macos-tool [args...]
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST_LIBS="${IOSIM_HOST_LIBS:-libc++.so.1:libc++abi.so.1:libarchive.so.13:libbz2.so.1.0:libcrypto.so.3}"
if [ ! -x "$ROOT/build/iosim-run" ]; then
    echo "build iosim-run first: cmake -S . -B build && cmake --build build" >&2
    exit 1
fi
if [ "$#" -eq 0 ]; then
    echo "usage: tools/host-run.sh /path/to/macos-tool [args...]" >&2
    exit 1
fi
exec env DYLD_ROOT_PATH="$ROOT/runtime" \
    IOSIM_HOST_SYMBOLS=1 \
    IOSIM_HOST_LIBS="$HOST_LIBS" \
    "$ROOT/build/iosim-run" "$@"
