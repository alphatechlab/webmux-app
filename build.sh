#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="WebmuxClient"
APP_BUNDLE="Webmux.app"

echo "Building ${APP_NAME}..."
swift build -c release

echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp ".build/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

cat > "${APP_BUNDLE}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>WebmuxClient</string>
    <key>CFBundleIdentifier</key>
    <string>com.alphatechlab.webmux-client</string>
    <key>CFBundleName</key>
    <string>Webmux</string>
    <key>CFBundleDisplayName</key>
    <string>Webmux</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
PLIST

echo "Code signing..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo ""
echo "Done! App bundle: ${SCRIPT_DIR}/${APP_BUNDLE}"
echo ""
echo "To install: cp -r ${APP_BUNDLE} /Applications/"
echo "To run:     open ${APP_BUNDLE}"
