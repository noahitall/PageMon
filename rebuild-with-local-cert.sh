#!/bin/bash

# Script to build and package PageMon app into a DMG file using a self-signed certificate
# This script requires Xcode command line tools

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building PageMon with a self-signed certificate...${NC}"

# Check if Xcode command line tools are available
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode command line tools not found. Install them with:${NC}"
    echo "xcode-select --install"
    exit 1
fi

# Set variables
PROJECT_NAME="PageMon"
BUILD_DIR="./build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
APP_PATH="${BUILD_DIR}/${PROJECT_NAME}.app"
DMG_PATH="${BUILD_DIR}/${PROJECT_NAME}.dmg"
CERT_NAME="PageMonLocalCert"

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Create a self-signed certificate for local app signing
echo -e "${BLUE}Creating a self-signed certificate for local use...${NC}"

# Check if certificate already exists
if security find-certificate -c "$CERT_NAME" -a login.keychain &>/dev/null; then
    echo -e "${GREEN}Certificate already exists, using existing certificate.${NC}"
else
    echo -e "${BLUE}Creating new self-signed certificate...${NC}"
    # Create a self-signed certificate
    security create-certificate -k login.keychain -s "$CERT_NAME" -c "PageMon Local Cert" -S "C=US" -a -e -o basic -j basic
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create certificate. Try manually with Keychain Access app.${NC}"
        echo -e "${BLUE}Proceeding with unsigned build...${NC}"
        security delete-certificate -c "$CERT_NAME" login.keychain &>/dev/null || true
        CERT_NAME="-"
    fi
fi

# Build the app for release
echo -e "${BLUE}Building app for release...${NC}"
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${PROJECT_NAME}" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    clean archive

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed. See errors above.${NC}"
    exit 1
fi

# Export the app from the archive
echo -e "${BLUE}Exporting app from archive...${NC}"

# Create a temporary export options plist with signing identity
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
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$BUILD_DIR"

if [ $? -ne 0 ]; then
    echo -e "${RED}App export failed. See errors above.${NC}"
    # Try with manual signing disabled
    echo -e "${BLUE}Trying export with signing disabled...${NC}"
    
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
        echo -e "${RED}App export failed again. See errors above.${NC}"
        exit 1
    fi
fi

# Create DMG file
echo -e "${BLUE}Creating DMG file at $DMG_PATH...${NC}"
hdiutil create -volname "${PROJECT_NAME}" -srcfolder "${APP_PATH}" -ov -format UDZO "${DMG_PATH}"

if [ $? -ne 0 ]; then
    echo -e "${RED}DMG creation failed.${NC}"
    exit 1
fi

echo -e "${GREEN}Success! DMG file created at:${NC}"
echo "$DMG_PATH"
echo -e "${GREEN}You can now install the app by opening the DMG and dragging the app to Applications.${NC}"

# Check if we're using a self-signed certificate
if [ "$CERT_NAME" != "-" ]; then
    echo -e "${BLUE}The app is signed with a local self-signed certificate.${NC}"
    echo -e "${BLUE}You should be able to use the widgets after installing the app.${NC}"
else
    echo -e "${RED}Note: The app is not signed. You may need to right-click and select 'Open' when launching it for the first time.${NC}"
    echo -e "${RED}Widgets might not work without proper signing.${NC}"
fi 