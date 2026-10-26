#!/bin/zsh
# XcodeSwitcher.app をビルドして ~/Applications に置く
set -e
cd "$(dirname "$0")/.."

swift build -c release

APP=build/XcodeSwitcher.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/XcodeSwitcher" "$APP/Contents/MacOS/XcodeSwitcher"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Xcode Switcher</string>
    <key>CFBundleIdentifier</key><string>io.github.xcode-switcher</string>
    <key>CFBundleExecutable</key><string>XcodeSwitcher</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict>
</plist>
EOF

mkdir -p ~/Applications
rm -rf ~/Applications/XcodeSwitcher.app
cp -R "$APP" ~/Applications/
echo "installed: ~/Applications/XcodeSwitcher.app"
