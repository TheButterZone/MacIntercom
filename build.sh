#!/bin/zsh

set -e

# Safely default to the host machine's architecture if no argument is provided
if [ -z "$1" ]; then
    ARCH=$(uname -m)
else
    ARCH="$1"
fi

if [ "$ARCH" = "arm64" ]; then
    TARGET_FLAG="arm64-apple-macosx11.0"
    OBJ_DIR=".build/obj_arm64"
else
    TARGET_FLAG="x86_64-apple-macosx10.15"
    OBJ_DIR=".build/obj_x86"
fi

OUTPUT_BIN="bin/macintercom"

echo "Preparing production build environment for $ARCH (Target: $TARGET_FLAG)..."
mkdir -p bin
mkdir -p "$OBJ_DIR/stub" "$OBJ_DIR/vad" "$OBJ_DIR/sp"

# Create the rtc_FatalMessage implementation stub if it doesn't already exist
if [ ! -f Sources/WebRTCVAD/rtc_stub.c ]; then
    cat << 'EOF' > Sources/WebRTCVAD/rtc_stub.c
#include <stdio.h>
#include <stdlib.h>

void rtc_FatalMessage(const char* file, int line, const char* msg) {
    fprintf(stderr, "FATAL ERROR in %s:%d - %s\n", file, line, msg);
    abort();
}
EOF
fi

echo "Compiling C sources with clang for $ARCH (Optimized)..."
clang -target "$TARGET_FLAG" -c -O3 Sources/WebRTCVAD/rtc_stub.c -o "$OBJ_DIR/stub/rtc_stub.o"

# Compile VAD C files with optimization
for cfile in Sources/WebRTCVAD/webrtc/common_audio/vad/*.c; do
    clang -target "$TARGET_FLAG" -c -O3 "$cfile" \
      -DWEBRTC_POSIX \
      -I Sources/WebRTCVAD \
      -o "$OBJ_DIR/vad/$(basename "$cfile" .c).o"
done

# Compile Signal Processing C files with optimization
for cfile in Sources/WebRTCVAD/webrtc/common_audio/signal_processing/*.c; do
    clang -target "$TARGET_FLAG" -c -O3 "$cfile" \
      -DWEBRTC_POSIX \
      -I Sources/WebRTCVAD \
      -o "$OBJ_DIR/sp/$(basename "$cfile" .c).o"
done

echo "Compiling Swift files and linking (Optimized release mode)..."
swiftc \
  Sources/*.swift \
  Sources/WebRTCVAD/WebRTCVAD.swift \
  "$OBJ_DIR/stub/"*.o \
  "$OBJ_DIR/vad/"*.o \
  "$OBJ_DIR/sp/"*.o \
  -import-objc-header Sources/MacIntercom-Bridging-Header.h \
  -I Sources/WebRTCVAD \
  -target "$TARGET_FLAG" \
  -O \
  -o "$OUTPUT_BIN"

echo "Cleaning up temporary build artifacts for $ARCH..."
rm -rf "$OBJ_DIR"

echo "Done! Clean production build output: $OUTPUT_BIN"