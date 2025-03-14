#!/bin/bash

# Script to package the PageMon content fetcher into a distributable ZIP file

set -e

echo "Packaging PageMon Content Fetcher..."

# Create a staging directory
STAGING_DIR="./PageMonInstaller"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Create installer contents
echo "Preparing installer contents..."

# Copy content fetcher files
mkdir -p "$STAGING_DIR/PageContentFetcher"
cp -r PageContentFetcher/*.js "$STAGING_DIR/PageContentFetcher/"
cp -r PageContentFetcher/*.sh "$STAGING_DIR/PageContentFetcher/"
cp -r PageContentFetcher/package.json "$STAGING_DIR/PageContentFetcher/"
cp -r PageContentFetcher/README.md "$STAGING_DIR/PageContentFetcher/"

# Create a README for the installer
cat > "$STAGING_DIR/README.txt" << 'EOF'
PageMon Content Fetcher Installer

This package contains the PageMon content fetcher, which is required
for the PageMon widget to extract content from websites.

Installation Instructions:
1. Extract the ZIP file
2. Open Terminal
3. Navigate to the extracted PageContentFetcher directory
4. Run ./install.sh
5. Follow the prompts in the installer
6. Update your widget code to use the installed path

Requirements:
- macOS 10.15 or later
- Node.js 14 or later

After installation, you will need to update your widget code to use the
installed content fetcher path. The installer will show you the path to use.

Support:
If you encounter any issues, please check the troubleshooting section
in the PageContentFetcher/README.md file.
EOF

# Create ZIP file
echo "Creating ZIP file..."
ZIP_NAME="PageMonInstaller.zip"
rm -f "$ZIP_NAME"

# Navigate to the staging directory and zip the contents
cd "$STAGING_DIR"
zip -r "../$ZIP_NAME" .
cd ..

echo "Cleaning up..."
rm -rf "$STAGING_DIR"

echo "Done! Installer ZIP created: $ZIP_NAME"
echo "Users can extract this ZIP and run PageContentFetcher/install.sh to install PageMon content fetcher." 