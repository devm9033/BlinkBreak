#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=== Building BlinkBreak for macOS (Release) ==="
swift build -c release

APP_NAME="BlinkBreak"
APP_DIR="$DIR/build/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

echo "=== Packaging $APP_NAME.app ==="
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp "$DIR/.build/release/$APP_NAME" "$MACOS_DIR/"

# Ensure AppIcon.icns exists
if [ ! -f "$DIR/AppIcon.icns" ]; then
    echo "=== Generating AppIcon.icns ==="
    swift "$DIR/generate_icon.swift"
    iconutil -c icns "$DIR/AppIcon.iconset" -o "$DIR/AppIcon.icns"
fi

# Copy AppIcon to Resources
cp "$DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

# Create Info.plist with AppIcon
cat << 'EOF' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BlinkBreak</string>
    <key>CFBundleIdentifier</key>
    <string>com.antigravity.blinkbreak</string>
    <key>CFBundleName</key>
    <string>BlinkBreak</string>
    <key>CFBundleDisplayName</key>
    <string>BlinkBreak</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Ad-hoc code sign for local execution
echo "=== Signing $APP_NAME.app ==="
codesign --force --deep --sign - "$APP_DIR"

echo "=== Successfully built $APP_DIR ==="
