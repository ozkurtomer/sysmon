#!/bin/bash
# Regenerates README media (GIFs, screenshots, social preview) from the real SwiftUI view.
# Requires: Xcode Command Line Tools and Pillow (pip install pillow).
set -euo pipefail
cd "$(dirname "$0")/.."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

swiftc -O Sources/*.swift -o "$TMP/sysmon"
for lang in en tr; do
  "$TMP/sysmon" --snapshot "$TMP/frames-$lang" "$lang"
  python3 assets/compose_demo.py "$TMP/frames-$lang" "$lang"
done
