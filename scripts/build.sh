#!/bin/bash
# Builds a universal (Apple Silicon + Intel) SysMon.app and a drag-to-install DMG.
# Usage: ./scripts/build.sh            (VERSION=1.2.0 ./scripts/build.sh to set the version)
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="SysMon"
VERSION="${VERSION:-1.0.0}"
APP="build/$NAME.app"
rm -rf build && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -target arm64-apple-macos13.0  Sources/*.swift -o build/sysmon-arm64
swiftc -O -target x86_64-apple-macos13.0 Sources/*.swift -o build/sysmon-x86_64
lipo -create build/sysmon-arm64 build/sysmon-x86_64 -output "$APP/Contents/MacOS/$NAME"
rm build/sysmon-arm64 build/sysmon-x86_64
cp assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$NAME</string>
  <key>CFBundleDisplayName</key><string>SysMon</string>
  <key>CFBundleIdentifier</key><string>com.ozkurtomer.sysmon</string>
  <key>CFBundleExecutable</key><string>$NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleLocalizations</key><array><string>en</string><string>tr</string></array>
  <key>NSHumanReadableCopyright</key><string>Copyright © 2026 Ömer Özkurt. MIT License.</string>
  <key>LSUIElement</key><true/>
</dict></plist>
EOF

codesign --force --sign - "$APP"   # ad-hoc signature

mkdir -p build/dmg && cp -R "$APP" build/dmg/ && ln -s /Applications build/dmg/Applications
hdiutil create -volname "$NAME" -srcfolder build/dmg -ov -format UDZO "build/$NAME.dmg" >/dev/null
rm -rf build/dmg
echo "Built build/$NAME.app and build/$NAME.dmg (v$VERSION)"
