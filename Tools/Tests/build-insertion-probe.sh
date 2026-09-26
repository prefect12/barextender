#!/bin/zsh
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
probe_path="$repo_root/build/test-bin/MenuBarInsertionProbe.app"
mkdir -p "$probe_path/Contents/MacOS"
xcrun swiftc -module-cache-path "$repo_root/build/barextender-swift-module-cache" \
    "$repo_root/Tools/Tests/MenuBarInsertionProbe.swift" \
    -o "$probe_path/Contents/MacOS/MenuBarInsertionProbe"
cat > "$probe_path/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.barextender.insertion-probe</string>
<key>CFBundleName</key><string>MenuBarInsertionProbe</string>
<key>CFBundleExecutable</key><string>MenuBarInsertionProbe</string>
<key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
PLIST
codesign --force --sign - "$probe_path"
print "$probe_path"
