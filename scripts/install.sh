#!/bin/bash
# SysMon installer — downloads the latest release and installs it without macOS's
# "Apple could not verify…" warning (files fetched with curl are not quarantined).
#
#   curl -fsSL https://raw.githubusercontent.com/ozkurtomer/sysmon/main/scripts/install.sh | bash
#
# Optional: INSTALL_DIR=~/Applications to install somewhere else.
set -euo pipefail

REPO="ozkurtomer/sysmon"
APP="SysMon.app"
DEST="${INSTALL_DIR:-/Applications}"
URL="https://github.com/$REPO/releases/latest/download/SysMon.dmg"

[ "$(uname)" = "Darwin" ] || { echo "SysMon is for macOS only."; exit 1; }

TMP="$(mktemp -d)"
cleanup() { hdiutil detach "$TMP/mnt" -quiet 2>/dev/null || true; rm -rf "$TMP"; }
trap cleanup EXIT

echo "→ Downloading SysMon…"
curl -fsSL "$URL" -o "$TMP/SysMon.dmg"

echo "→ Installing to $DEST…"
mkdir -p "$TMP/mnt" "$DEST"
hdiutil attach "$TMP/SysMon.dmg" -nobrowse -readonly -quiet -mountpoint "$TMP/mnt"

pkill -x SysMon 2>/dev/null || true
rm -rf "$DEST/$APP"
cp -R "$TMP/mnt/$APP" "$DEST/$APP"
xattr -dr com.apple.quarantine "$DEST/$APP" 2>/dev/null || true   # safety net

echo "→ Launching…"
open "$DEST/$APP"
echo "✓ SysMon is installed. Look for it in your menu bar."
