#!/bin/bash

# Script to build and package PageMon app into a DMG file
# This script requires Xcode command line tools and create-dmg utility

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building and packaging PageMon into DMG...${NC}"

# Check if Xcode command line tools are available
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode command line tools not found. Install them with:${NC}"
    echo "xcode-select --install"
    exit 1
fi

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo -e "${RED}Error: create-dmg not found. Install it with:${NC}"
    echo "brew install create-dmg"
    exit 1
fi

# Set variables
PROJECT_NAME="PageMon"
BUILD_DIR="./build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
APP_PATH="${BUILD_DIR}/${PROJECT_NAME}.app"
DMG_PATH="${BUILD_DIR}/${PROJECT_NAME}.dmg"

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the app for release
echo -e "${BLUE}Building app for release...${NC}"
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${PROJECT_NAME}" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    clean archive

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed. See errors above.${NC}"
    exit 1
fi

# Export the app from the archive
echo -e "${BLUE}Exporting app from archive...${NC}"

# Create a temporary export options plist with minimal signing for local use
EXPORT_OPTIONS="${BUILD_DIR}/export_options.plist"
cat > "$EXPORT_OPTIONS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>signingCertificate</key>
    <string>-</string>
    <key>provisioningProfiles</key>
    <dict/>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$BUILD_DIR" \
    -allowProvisioningUpdates

if [ $? -ne 0 ]; then
    echo -e "${RED}App export failed. See errors above.${NC}"
    exit 1
fi

# Create DMG file
echo -e "${BLUE}Creating DMG file...${NC}"
create-dmg \
    --volname "${PROJECT_NAME}" \
    --volicon "PageMon/Assets.xcassets/AppIcon.appiconset/AppIcon.icns" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 100 \
    --icon "${PROJECT_NAME}.app" 200 190 \
    --hide-extension "${PROJECT_NAME}.app" \
    --app-drop-link 600 185 \
    "$DMG_PATH" \
    "${APP_PATH}"

if [ $? -ne 0 ]; then
    echo -e "${RED}DMG creation failed. See errors above.${NC}"
    
    # Simplified DMG creation as fallback
    echo -e "${BLUE}Trying simplified DMG creation...${NC}"
    hdiutil create -volname "${PROJECT_NAME}" -srcfolder "${APP_PATH}" -ov -format UDZO "${DMG_PATH}"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Simplified DMG creation also failed.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Success! DMG file created at:${NC}"
echo "$DMG_PATH"
echo -e "${GREEN}You can now install the app by opening the DMG and dragging the app to Applications.${NC}"
echo -e "${RED}Note: Since this app is not signed with a Developer ID, you may need to right-click and select 'Open' when launching it for the first time.${NC}" 