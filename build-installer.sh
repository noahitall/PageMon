#!/bin/bash

# Script to build a DMG installer for PageMon content fetcher
# This creates a DMG file that users can mount and run the installer script

set -e

echo "Building PageMon Installer DMG..."

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
cp -r PageContentFetcher/install.sh "$STAGING_DIR/install.sh"
cp debug-fetcher.swift "$STAGING_DIR/"

# Make sure scripts are executable
chmod +x "$STAGING_DIR/PageContentFetcher"/*.js "$STAGING_DIR/PageContentFetcher"/*.sh "$STAGING_DIR/install.sh" "$STAGING_DIR/debug-fetcher.swift"

# Create a troubleshooting guide
cat > "$STAGING_DIR/Troubleshooting.md" << 'EOF'
# PageMon Troubleshooting Guide

If you're experiencing issues with the PageMon widget, this guide will help you diagnose and resolve them.

## Common Issues and Solutions

### Widget Shows "Failed to verify Node.js environment"

This error occurs when the widget cannot properly execute the Node.js scripts needed to fetch content.

**Solutions:**

1. **Run the diagnostic script**:
   ```bash
   cd /path/to/PageContentFetcher
   ./diagnose-widget.sh
   ```
   This will generate detailed logs in `/tmp/PageMonLogs/` that can help identify the issue.

2. **Check Node.js installation**:
   Make sure Node.js is installed and in your PATH:
   ```bash
   node --version
   ```
   If not installed, download from [nodejs.org](https://nodejs.org/).

3. **Verify script permissions**:
   ```bash
   chmod +x /path/to/PageContentFetcher/*.js
   chmod +x /path/to/PageContentFetcher/*.sh
   ```

4. **Test direct content fetching**:
   ```bash
   cd /path/to/PageContentFetcher
   ./direct-fetch.js --url="https://example.com" --selector="h1" --debug
   ```

### Widget Shows "Failed to parse response"

This error indicates the widget received a response from the content fetcher but couldn't parse it as valid JSON.

**Solutions:**

1. **Check the logs**:
   Look at the log file indicated in the error message for details.

2. **Test the content fetcher manually**:
   ```bash
   cd /path/to/PageContentFetcher
   ./direct-fetch.js --url="your-url" --selector="your-selector" --debug
   ```

3. **Use the debug helper script**:
   ```bash
   ./debug-fetcher.swift --url="your-url" --selector="your-selector" --verbose
   ```
   This Swift script will test the content fetcher with detailed logging and diagnose any issues.

### Widget Shows "No content received from fetcher"

This error indicates that the content fetcher is failing to return any data to the widget.

**Solutions:**

1. **Test with the debug helper**:
   ```bash
   ./debug-fetcher.swift --url="your-url" --selector="your-selector" --verbose
   ```
   This will show exactly what's happening when trying to fetch content.

2. **Check the direct execution of the script**:
   ```bash
   node /path/to/PageContentFetcher/direct-fetch.js --url="your-url" --selector="your-selector" --debug
   ```

3. **Check the logs**:
   Look at the log files in `/tmp/PageMonLogs/` for errors.

### Widget Shows "No content found with selector"

This means the content fetcher connected to the website but couldn't find content matching your selector.

**Solutions:**

1. **Verify your selector**:
   Use browser developer tools to confirm your selector is correct.

2. **Test with JavaScript rendering**:
   Some websites require JavaScript to render content. Try enabling the JavaScript option in the widget configuration.

### Advanced Fixes

If you're still having issues, try:

1. **Reinstalling the content fetcher**:
   ```bash
   ./install.sh
   ```

2. **Update Node.js dependencies**:
   ```bash
   cd /path/to/PageContentFetcher
   npm install
   ```

3. **Check the full diagnostic logs**:
   Logs are stored in `/tmp/PageMonLogs/` and contain detailed information about what's happening.

## Getting More Help

If you're still experiencing issues, please check the PageMon repository for updates or file an issue with:

1. The specific error message
2. The URL and selector you're trying to use
3. The logs from `/tmp/PageMonLogs/`
4. The output of the diagnostic script
EOF

# Create a README for the installer
cat > "$STAGING_DIR/README.txt" << 'EOF'
PageMon Content Fetcher Installer

This installer will set up the PageMon content fetcher, which is required
for the PageMon widget to extract content from websites.

Installation Instructions:
1. Double-click install.sh
2. If prompted, choose to open with Terminal
3. Follow the prompts in the installer
4. Select your preferred installation location

Requirements:
- macOS 10.15 or later
- Node.js 14 or later

After installation, the PageMon widget will automatically find the content fetcher
in its standard locations.

Support:
If you encounter any issues, please check Troubleshooting.md for solutions.
EOF

# Create a simple launcher script for less technical users
cat > "$STAGING_DIR/Install PageMon.command" << 'EOF'
#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run the installer
"$SCRIPT_DIR/install.sh"

# Keep the terminal window open until the user presses Enter
echo
echo "Press Enter to close this window..."
read
EOF

chmod +x "$STAGING_DIR/Install PageMon.command"

# Create DMG
echo "Creating DMG file..."
DMG_NAME="PageMonInstaller.dmg"
rm -f "$DMG_NAME"

hdiutil create -volname "PageMon Installer" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

echo "Cleaning up..."
rm -rf "$STAGING_DIR"

echo "Done! Installer DMG created: $DMG_NAME"
echo "Users can mount this DMG and run install.sh or 'Install PageMon.command' to install PageMon content fetcher." 