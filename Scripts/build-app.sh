#!/bin/zsh
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
app_root="$project_root/outputs/Aura.app"
iconset_root="$project_root/Assets/Aura.iconset"

swift "$project_root/Scripts/render-icon.swift" "$project_root/Assets/Aura-AppIcon.png"
mkdir -p "$iconset_root"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$project_root/Assets/Aura-AppIcon.png" --out "$iconset_root/icon_${size}x${size}.png" >/dev/null
  doubled=$((size * 2))
  sips -z "$doubled" "$doubled" "$project_root/Assets/Aura-AppIcon.png" --out "$iconset_root/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset_root" -o "$project_root/Assets/Aura.icns"

swift build -c release --package-path "$project_root"
rm -rf "$app_root"
mkdir -p "$app_root/Contents/MacOS" "$app_root/Contents/Resources"
cp "$project_root/.build/release/AuraWeather" "$app_root/Contents/MacOS/AuraWeather"
cp "$project_root/Assets/Aura.icns" "$app_root/Contents/Resources/Aura.icns"
cat > "$app_root/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDisplayName</key><string>Aura</string>
  <key>CFBundleExecutable</key><string>AuraWeather</string>
  <key>CFBundleIconFile</key><string>Aura</string>
  <key>CFBundleIdentifier</key><string>local.aura.weather</string>
  <key>CFBundleName</key><string>Aura</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSLocationWhenInUseUsageDescription</key><string>Aura uses your location to show local weather.</string>
</dict></plist>
PLIST
codesign --force --deep --sign - "$app_root"
echo "Created: $app_root"
