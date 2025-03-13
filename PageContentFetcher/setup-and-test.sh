#!/bin/bash

# Script to setup and test the PageContentFetcher

# Ensure script exits on error
set -e

# Get directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "📦 Installing dependencies..."
npm install

echo "🔑 Making scripts executable..."
chmod +x index.js
chmod +x test.js

echo "🧪 Running a simple test..."
./test.js --url="https://example.com" --selector="h1"

echo "🚀 Testing with JavaScript rendering..."
./test.js --url="https://www.nytimes.com" --selector=".css-1nq8vpa" --useJavaScript

echo "✅ Setup and tests completed successfully!"
echo ""
echo "To run your own tests, use:"
echo "./test.js --url=\"https://example.com\" --selector=\"h1\" [--useJavaScript]"
echo ""
echo "To use in your widget, ensure the path in PageWidget.swift is correct:"
echo "let scriptPath = \"$SCRIPT_DIR/index.js\"" 