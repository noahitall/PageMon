#!/bin/bash

# PageMon Content Fetcher Installer
# This script installs the PageMon content fetcher to a standard location

set -e

# Set terminal colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${BLUE}┃           PageMon Content Fetcher Installer        ┃${NC}"
echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo

# Get this script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Determine install location
echo -e "${YELLOW}Select installation location:${NC}"
echo "1) User Applications ($HOME/Applications/PageMon) [Recommended]"
echo "2) System Applications (/Applications/PageMon) [Requires admin]"
echo "3) Custom location"
echo
read -p "Enter choice [1-3] (default: 1): " CHOICE

case $CHOICE in
    2)
        INSTALL_DIR="/Applications/PageMon"
        SUDO_REQUIRED=true
        ;;
    3)
        read -p "Enter custom installation path: " CUSTOM_PATH
        INSTALL_DIR="${CUSTOM_PATH}"
        # Check if we need sudo for the custom path
        if [[ "$INSTALL_DIR" == "/usr/"* || "$INSTALL_DIR" == "/opt/"* || "$INSTALL_DIR" == "/Library/"* ]]; then
            SUDO_REQUIRED=true
        fi
        ;;
    *)
        INSTALL_DIR="$HOME/Applications/PageMon"
        SUDO_REQUIRED=false
        ;;
esac

echo
echo -e "Installing to: ${GREEN}$INSTALL_DIR${NC}"

# Create command prefix with sudo if required
CMD_PREFIX=""
if [ "$SUDO_REQUIRED" = true ]; then
    echo "This location requires administrator privileges."
    CMD_PREFIX="sudo"
fi

# Create directories
echo "Creating directories..."
$CMD_PREFIX mkdir -p "$INSTALL_DIR"
$CMD_PREFIX mkdir -p "$INSTALL_DIR/PageContentFetcher"

# Copy files
echo "Copying files..."
$CMD_PREFIX cp -r "$SCRIPT_DIR"/*.js "$INSTALL_DIR/PageContentFetcher/"
$CMD_PREFIX cp -r "$SCRIPT_DIR"/*.sh "$INSTALL_DIR/PageContentFetcher/"
$CMD_PREFIX cp -r "$SCRIPT_DIR/package.json" "$INSTALL_DIR/PageContentFetcher/"
$CMD_PREFIX cp -r "$SCRIPT_DIR/README.md" "$INSTALL_DIR/PageContentFetcher/"

# Set permissions
echo "Setting permissions..."
$CMD_PREFIX chmod +x "$INSTALL_DIR/PageContentFetcher"/*.js
$CMD_PREFIX chmod +x "$INSTALL_DIR/PageContentFetcher"/*.sh

# Set ownership if necessary
if [ "$SUDO_REQUIRED" = true ]; then
    echo "Setting ownership..."
    sudo chown -R $(whoami) "$INSTALL_DIR"
fi

# Verify and install Node.js dependencies
echo "Checking Node.js environment..."
cd "$INSTALL_DIR/PageContentFetcher"
./install-verify.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}Error during verification. Installation may not be complete.${NC}"
    echo "Please check the logs and try to resolve any issues before using the widget."
    exit 1
fi

# Setup Node.js symlinks for widget compatibility
echo "Setting up Node.js symlinks for widget compatibility..."
echo "This ensures the widget can locate Node.js in its restricted environment."

# Determine if Node.js is available and create symlinks
NODE_PATH=$(which node 2>/dev/null || echo "")
if [ -n "$NODE_PATH" ]; then
    echo "Found Node.js at: $NODE_PATH"
    # Only create symlink if we have sudo or if the target directory is writable
    if [ -w "/usr/local/bin" ] || [ "$SUDO_REQUIRED" = true ]; then
        echo "Creating Node.js symlink in /usr/local/bin..."
        $CMD_PREFIX mkdir -p /usr/local/bin
        $CMD_PREFIX ln -sf "$NODE_PATH" /usr/local/bin/node
        echo "✅ Node.js symlink created"
    else
        echo "⚠️ Cannot create Node.js symlink without administrator privileges."
        echo "   The widget may not be able to find Node.js."
        echo "   You can run the fix-node-symlinks.sh script later to resolve this."
    fi
else
    echo "⚠️ Node.js not found in PATH. The widget may not function correctly."
    echo "   Please install Node.js and then run fix-node-symlinks.sh."
fi

# Copy the debug fetcher script
echo "Copying debug-fetcher.swift..."
cp -f "$SCRIPT_DIR/../debug-fetcher.swift" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/debug-fetcher.swift"

# Link the debug script for easier access
if [[ "$INSTALL_DIR" != "/usr/local/bin" && "$INSTALL_DIR" != "/usr/bin" ]]; then
    echo "Creating symbolic link to debug-fetcher.swift in /usr/local/bin..."
    sudo ln -sf "$INSTALL_DIR/debug-fetcher.swift" /usr/local/bin/pagemon-debug
    if [ $? -eq 0 ]; then
        echo "✅ Created symbolic link: /usr/local/bin/pagemon-debug"
    else
        echo "⚠️ Could not create symbolic link. You can still run the debug script directly from: $INSTALL_DIR/debug-fetcher.swift"
    fi
fi

echo -e "\n${GREEN}✅ Installation completed successfully!${NC}"
echo
echo "Please update your PageWidget configuration to use this path:"
echo -e "${BLUE}$INSTALL_DIR/PageContentFetcher/index.js${NC}"
echo
echo "Instructions for updating your widget:"
echo "1. Open your Xcode project"
echo "2. Edit PageWidget.swift"
echo "3. Make sure this path is included in the possibleScriptDirs array:"
echo "   \"$INSTALL_DIR/PageContentFetcher\""
echo
echo -e "${GREEN}Thank you for using PageMon!${NC}"

exit 0 