#!/bin/bash

# Script to build and run the PageMon Debug App

set -e

echo "Building PageMon Debug App..."

# Check if swiftc is available
if ! command -v swiftc &> /dev/null; then
    echo "Error: Swift compiler not found. Make sure Xcode and Swift are installed."
    exit 1
fi

# Create build directory
BUILD_DIR="./build"
mkdir -p "$BUILD_DIR"

# Create temporary directory for logs
LOG_DIR="/tmp/PageMonLogs"
mkdir -p "$LOG_DIR"

# Compile the app
echo "Compiling..."
swiftc -o "$BUILD_DIR/PageMonDebug" \
    -sdk "$(xcrun --show-sdk-path)" \
    -target arm64-apple-macosx14.0 \
    -I "$(xcrun --show-sdk-path)/System/Library/Frameworks/AppKit.framework/Headers" \
    -I "$(xcrun --show-sdk-path)/System/Library/Frameworks/Foundation.framework/Headers" \
    -I "$(xcrun --show-sdk-path)/System/Library/Frameworks/WebKit.framework/Headers" \
    -framework AppKit \
    -framework Foundation \
    -framework WebKit \
    -framework SwiftUI \
    PageMon/ContentView.swift \
    PageMon/PageMonApp.swift

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Running PageMon Debug App..."
    "$BUILD_DIR/PageMonDebug"
else
    echo "Build failed. See errors above."
    exit 1
fi 