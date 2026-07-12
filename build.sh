#!/bin/zsh

set -e

echo "Compiling..."

mkdir -p bin

swiftc Sources/*.swift -o bin/macintercom

echo "Running..."

./bin/macintercom

echo "Done."
