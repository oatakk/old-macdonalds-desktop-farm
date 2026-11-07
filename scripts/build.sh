#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app='.build/Old MacDonalds Desktop Farm.app'
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
swiftc Sources/main.swift -o "$app/Contents/MacOS/Farm" -framework Cocoa -framework CoreAudio -O
cp -R Assets/Walk "$app/Contents/Resources/"
cp Assets/Farm.icns "$app/Contents/Resources/Farm.icns"
python3 - "$app" <<'PY'
import plistlib,sys
from pathlib import Path
p=Path(sys.argv[1])/'Contents/Info.plist'
p.write_bytes(plistlib.dumps(dict(CFBundleExecutable='Farm',CFBundleIconFile='Farm.icns',CFBundleIdentifier='com.oatakk.oldmacdonaldsdesktopfarm',CFBundleName='Old MacDonalds Desktop Farm',CFBundleDisplayName='Old MacDonald’s Desktop Farm',CFBundlePackageType='APPL',CFBundleShortVersionString='0.4.0',CFBundleVersion='4',LSMinimumSystemVersion='14.2',LSUIElement=True,NSHighResolutionCapable=True)))
PY
"$app/Contents/MacOS/Farm" --validate-assets
# Sign outside synced Documents folders, which may inject Finder metadata.
stage=$(mktemp -d "${TMPDIR:-/tmp}/desktop-farm.XXXXXX")
trap 'rm -rf "$stage"' EXIT
staged="$stage/Old MacDonalds Desktop Farm.app"
ditto --norsrc --noextattr "$app" "$staged"
xattr -cr "$staged"
codesign --force --sign - "$staged"
codesign --verify --deep --strict "$staged"
ditto -c -k --keepParent "$staged" .build/Old-MacDonalds-Desktop-Farm-macOS.zip
echo "Built: .build/Old-MacDonalds-Desktop-Farm-macOS.zip"
