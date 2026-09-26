#!/bin/zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

# Keep the machine's certificate selection outside version control.
identity="${BAREXTENDER_SIGNING_IDENTITY:-}"
if [[ -z "$identity" && -f build/signing-identity.txt ]]; then
    identity="$(<build/signing-identity.txt)"
fi
if [[ -z "$identity" || "$identity" == "-" ]]; then
    print -u2 'Set BAREXTENDER_SIGNING_IDENTITY to an existing code-signing certificate name or SHA-1.'
    print -u2 'Reuse the same certificate for subsequent builds to retain macOS privacy permissions.'
    exit 1
fi

xcodebuild \
    -project Barextender.xcodeproj \
    -scheme Barextender \
    -configuration Debug \
    -derivedDataPath build/BarextenderDerivedData \
    -clonedSourcePackagesDirPath build/SourcePackages \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$identity" \
    CODE_SIGNING_REQUIRED=YES \
    CODE_SIGNING_ALLOWED=YES \
    DEVELOPMENT_TEAM= \
    ENABLE_HARDENED_RUNTIME=NO \
    ENABLE_DEBUG_DYLIB=NO \
    OTHER_CODE_SIGN_FLAGS=--timestamp=none \
    build

app_path="$repo_root/build/BarextenderDerivedData/Build/Products/Debug/Barextender.app"
codesign --verify --deep --strict "$app_path"
codesign -d -r- "$app_path"
print "Built: $app_path"
