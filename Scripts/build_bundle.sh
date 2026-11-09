#!/usr/bin/env bash
set -e

# ==============================================================================
# Android File Transfer Pro - Automated macOS App Bundle & Release Builder
# Targets: macOS 27+ (Apple Silicon arm64)
# ==============================================================================

APP_NAME="Android File Transfer Pro"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
EXECUTABLE_NAME="AndroidFileTransfer"
CACHE_DIR="/tmp/clang-cache"

echo "============================================================"
echo "🚀 Building ${APP_NAME} for macOS..."
echo "============================================================"

mkdir -p "${CACHE_DIR}"

# Step 1: Generate App Icon if missing
if [ ! -f "Resources/AppIcon.icns" ]; then
    echo "🎨 Generating macOS high-resolution app icon..."
    mkdir -p Resources
    swiftc -module-cache-path "${CACHE_DIR}" Scripts/generate_icons.swift -o Scripts/gen_icons
    ./Scripts/gen_icons
    iconutil -c icns AppIcon.iconset -o Resources/AppIcon.icns
    rm -rf AppIcon.iconset Scripts/gen_icons
fi

# Step 2: Create App Bundle directory structure
echo "📁 Assembling .app bundle directory structure..."
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Step 3: Compile Swift Sources with optimization
echo "⚡ Compiling Swift sources (Apple Silicon arm64 native)..."
swiftc -module-cache-path "${CACHE_DIR}" -O -parse-as-library \
    Sources/Models/Models.swift \
    Sources/Models/SpeedTracker.swift \
    Sources/Models/ViewModels.swift \
    Sources/Services/NetworkUtils.swift \
    Sources/Services/WebUIHTML.swift \
    Sources/Services/LocalWebServer.swift \
    Sources/Services/ADBService.swift \
    Sources/Services/TransferManager.swift \
    Sources/Views/Components/SpeedometerView.swift \
    Sources/Views/Components/SpeedGraphView.swift \
    Sources/Views/WifiPortalView.swift \
    Sources/Views/FileExplorerView.swift \
    Sources/Views/SpeedBenchmarkView.swift \
    Sources/Views/TransferLogsView.swift \
    Sources/Views/ConnectionGuideView.swift \
    Sources/Views/ContentView.swift \
    Sources/AppMain.swift \
    -o "${MACOS_DIR}/${EXECUTABLE_NAME}"

chmod +x "${MACOS_DIR}/${EXECUTABLE_NAME}"

# Step 4: Copy Metadata & Resources
echo "📋 Copying Info.plist and AppIcon.icns..."
cp Resources/Info.plist "${CONTENTS_DIR}/Info.plist"
cp Resources/AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"

if [ -d "Resources/platform-tools" ]; then
    echo "📦 Bundling official Google platform-tools (adb)..."
    cp -R Resources/platform-tools "${RESOURCES_DIR}/"
fi

# Create PkgInfo
echo -n "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Step 5: Ad-hoc Code Sign for Apple Silicon
echo "🔏 Code-signing bundle (ad-hoc)..."
codesign -s - --force --deep "${BUNDLE_DIR}"

echo "✅ App bundle created successfully: ${BUNDLE_DIR}"

# Step 6: Create release Zip archive preserving all macOS attributes
echo "📦 Packaging distributable release archive..."
rm -f "AndroidFileTransferPro.zip"
ditto -c -k --sequesterRsrc --keepParent "${BUNDLE_DIR}" "AndroidFileTransferPro.zip"
echo "✅ Release package created: AndroidFileTransferPro.zip"

echo "============================================================"
echo "🎉 Build Complete!"
echo "To run the app:"
echo "  open \"${BUNDLE_DIR}\""
echo "Or drag \"${BUNDLE_DIR}\" to your /Applications folder."
echo "============================================================"
