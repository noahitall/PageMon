#!/bin/bash

# Simple script to create a DMG from the built app

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Creating a simple DMG for PageMon...${NC}"

# Set variables
BUILD_DIR="./build"
APP_PATH="${BUILD_DIR}/PageMon.app"
DMG_PATH="${BUILD_DIR}/PageMon.dmg"

# Check if the built app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Built app not found at $APP_PATH${NC}"
    echo -e "${BLUE}Looking for app in other locations...${NC}"
    
    # Try to find the app in subdirectories
    FOUND_APP=$(find "$BUILD_DIR" -name "PageMon.app" -type d | head -n 1)
    
    if [ -z "$FOUND_APP" ]; then
        echo -e "${RED}Could not find built PageMon app. Please build the app first.${NC}"
        exit 1
    else
        APP_PATH="$FOUND_APP"
        echo -e "${GREEN}Found app at: $APP_PATH${NC}"
    fi
fi

# Create a simple DMG with hdiutil
echo -e "${BLUE}Creating DMG file at $DMG_PATH...${NC}"
hdiutil create -volname "PageMon" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"

if [ $? -ne 0 ]; then
    echo -e "${RED}DMG creation failed.${NC}"
    exit 1
fi

echo -e "${GREEN}Success! DMG file created at:${NC}"
echo "$DMG_PATH"
echo -e "${GREEN}You can now install the app by opening the DMG and dragging the app to Applications.${NC}"
echo -e "${RED}Note: Since this app is not signed with a Developer ID, you may need to right-click and select 'Open' when launching it for the first time.${NC}" 