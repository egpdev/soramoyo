#!/bin/zsh
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
app_root="$project_root/outputs/Soramoyo.app"
widget_root="$app_root/Contents/PlugIns/SoramoyoWidgets.appex"
iconset_root="$project_root/Assets/Aura.iconset"
development_identity="$(security find-identity -v -p codesigning | sed -n 's/.*"\(Apple Development:[^"]*\)".*/\1/p' | head -n 1)"
signing_identity="${development_identity:--}"

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
mkdir -p "$app_root/Contents/MacOS" "$app_root/Contents/Resources" "$widget_root/Contents/MacOS"
cp "$project_root/.build/release/AuraWeather" "$app_root/Contents/MacOS/AuraWeather"
cp "$project_root/Assets/Aura.icns" "$app_root/Contents/Resources/Aura.icns"

sdk_root="$(xcrun --sdk macosx --show-sdk-path)"
deployment_target="$(uname -m)-apple-macos14.0"
xcrun swiftc -parse-as-library -O -sdk "$sdk_root" -target "$deployment_target" \
  -module-name SoramoyoWidgets -framework Foundation -framework SwiftUI -framework WidgetKit \
  "$project_root/Widget/SoramoyoWidget.swift" -o "$widget_root/Contents/MacOS/SoramoyoWidgets"

cat > "$widget_root/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDisplayName</key><string>SORAMOYO</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>SoramoyoWidgets</string>
  <key>CFBundleIdentifier</key><string>local.soramoyo.weather.widget</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>SoramoyoWidgets</string>
  <key>CFBundlePackageType</key><string>XPC!</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleSupportedPlatforms</key><array><string>MacOSX</string></array>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSExtension</key><dict>
    <key>NSExtensionPointIdentifier</key><string>com.apple.widgetkit-extension</string>
  </dict>
</dict></plist>
PLIST
cat > "$app_root/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDisplayName</key><string>Soramoyo</string>
  <key>CFBundleExecutable</key><string>AuraWeather</string>
  <key>CFBundleIconFile</key><string>Aura</string>
  <key>CFBundleIdentifier</key><string>local.soramoyo.weather</string>
  <key>CFBundleName</key><string>Soramoyo</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSLocationWhenInUseUsageDescription</key><string>Soramoyo uses your location to show local weather.</string>
</dict></plist>
PLIST
codesign --force --options runtime --sign "$signing_identity" \
  --entitlements "$project_root/Widget/SoramoyoWidgets.entitlements" "$widget_root"
codesign --force --options runtime --sign "$signing_identity" "$app_root"
echo "Created: $app_root"
echo "Signed with: $signing_identity"
