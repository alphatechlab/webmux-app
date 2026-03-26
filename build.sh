#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="WebmuxClient"
APP_BUNDLE="Webmux.app"

# Get version from git tag or commit
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")
BUILD=$(git rev-parse --short HEAD 2>/dev/null || echo "dev")

echo "Building ${APP_NAME} ${VERSION} (${BUILD})..."
swift build -c release

echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp ".build/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy app icon
ICNS=$(find .build -name "AppIcon.icns" -path "*/release/*" 2>/dev/null | head -1)
if [ -n "$ICNS" ]; then
  cp "$ICNS" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
  echo "Copied app icon."
fi

# Copy resource bundles (SPM resources)
RESOURCE_BUNDLE=$(find .build -name "${APP_NAME}_${APP_NAME}.bundle" -path "*/release/*" 2>/dev/null | head -1)
if [ -n "$RESOURCE_BUNDLE" ]; then
  cp -r "$RESOURCE_BUNDLE" "${APP_BUNDLE}/Contents/Resources/"
  echo "Copied resource bundle."
fi

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
    <string>BUILD_PLACEHOLDER</string>
    <key>CFBundleShortVersionString</key>
    <string>VERSION_PLACEHOLDER</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
PLIST

# Inject version
sed -i '' "s/VERSION_PLACEHOLDER/${VERSION}/" "${APP_BUNDLE}/Contents/Info.plist"
sed -i '' "s/BUILD_PLACEHOLDER/${BUILD}/" "${APP_BUNDLE}/Contents/Info.plist"

echo "Code signing..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo ""
echo "Done! App bundle: ${SCRIPT_DIR}/${APP_BUNDLE}"
echo ""
echo "To install: cp -r ${APP_BUNDLE} /Applications/"
echo "To run:     open ${APP_BUNDLE}"
