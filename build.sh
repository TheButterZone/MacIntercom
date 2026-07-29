#!/bin/zsh

set -e

echo "Preparing build environment..."
mkdir -p bin
mkdir -p .build/obj/vad .build/obj/sp .build/obj/stub

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

echo "Compiling C sources with clang..."
clang -c Sources/WebRTCVAD/rtc_stub.c -o .build/obj/stub/rtc_stub.o

# Compile VAD C files into hidden object files
for cfile in Sources/WebRTCVAD/webrtc/common_audio/vad/*.c; do
    clang -c "$cfile" \
      -DWEBRTC_POSIX \
      -I Sources/WebRTCVAD \
      -o ".build/obj/vad/$(basename "$cfile" .c).o"
done

# Compile Signal Processing C files into hidden object files
for cfile in Sources/WebRTCVAD/webrtc/common_audio/signal_processing/*.c; do
    clang -c "$cfile" \
      -DWEBRTC_POSIX \
      -I Sources/WebRTCVAD \
      -o ".build/obj/sp/$(basename "$cfile" .c).o"
done

echo "Compiling Swift files and linking..."
swiftc \
  Sources/*.swift \
  Sources/WebRTCVAD/WebRTCVAD.swift \
  .build/obj/stub/*.o \
  .build/obj/vad/*.o \
  .build/obj/sp/*.o \
  -import-objc-header Sources/MacIntercom-Bridging-Header.h \
  -I Sources/WebRTCVAD \
  -o bin/macintercom

echo "Cleaning up temporary build artifacts..."
rm -rf .build

echo "Done! Build output is clean: bin/macintercom"

echo "Running..."

./bin/macintercom