#!/bin/sh
set -eu

SCRIPT_DIRECTORY="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_DIRECTORY="$(CDPATH= cd -- "$SCRIPT_DIRECTORY/../.." && pwd)"
TEST_BINARY="$PROJECT_DIRECTORY/build/test-bin/BarextenderModelTests"
SWIFT_MODULE_CACHE="$PROJECT_DIRECTORY/build/barextender-swift-module-cache"
SDK_MODULE_CACHE="$PROJECT_DIRECTORY/build/barextender-sdk-module-cache"

mkdir -p "$PROJECT_DIRECTORY/build/test-bin"
mkdir -p "$SWIFT_MODULE_CACHE" "$SDK_MODULE_CACHE"
xcrun swiftc \
  -module-name BarextenderModelTests \
  -module-cache-path "$SWIFT_MODULE_CACHE" \
  -sdk-module-cache-path "$SDK_MODULE_CACHE" \
  -o "$TEST_BINARY" \
  "$PROJECT_DIRECTORY/Ice/Utilities/ScreenCapturePermissionProbe.swift" \
  "$PROJECT_DIRECTORY/Ice/Utilities/MenuBarActivation.swift" \
  "$PROJECT_DIRECTORY/Ice/Utilities/MenuBarScreenRule.swift" \
  "$PROJECT_DIRECTORY/Ice/Localization/BarextenderLocalization.swift" \
  "$PROJECT_DIRECTORY/Ice/MenuBar/MenuBarItems/MenuBarLayoutIdentity.swift" \
  "$PROJECT_DIRECTORY/Ice/MenuBar/MenuBarItems/NewMenuBarItemPlacement.swift" \
  "$PROJECT_DIRECTORY/Ice/MenuBar/MenuBarItems/MenuBarPaletteItem.swift" \
  "$PROJECT_DIRECTORY/Tests/main.swift"

"$TEST_BINARY"
