#!/bin/bash

# Script to ensure Node.js is properly configured for use by the PageMon widget
# This script is called by the widget to verify the Node.js environment

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGS_DIR="/tmp/PageMonLogs"
LOG_FILE="$LOGS_DIR/node-env-check.log"

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "Starting Node.js environment check"
log "Script directory: $SCRIPT_DIR"

# Check if node is installed and available in PATH
NODE_PATH=$(which node)
if [ -z "$NODE_PATH" ]; then
    log "ERROR: Node.js not found in PATH"
    echo "ERROR: Node.js not found. Please install Node.js to use this widget."
    exit 1
fi

log "Node.js found at: $NODE_PATH"
NODE_VERSION=$(node --version)
log "Node.js version: $NODE_VERSION"

# Check if required modules are installed
cd "$SCRIPT_DIR"
log "Checking for required Node.js modules"

# Check if package.json exists
if [ ! -f "package.json" ]; then
    log "ERROR: package.json not found in $SCRIPT_DIR"
    echo "ERROR: package.json not found. Please run npm init in the PageContentFetcher directory."
    exit 1
fi

# Check if node_modules directory exists
if [ ! -d "node_modules" ]; then
    log "node_modules not found, running npm install"
    npm install >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "ERROR: npm install failed"
        echo "ERROR: Failed to install Node.js dependencies. See log at $LOG_FILE"
        exit 1
    fi
    log "npm install completed successfully"
fi

# Check if required scripts are executable
if [ ! -x "$SCRIPT_DIR/index.js" ]; then
    log "Making index.js executable"
    chmod +x "$SCRIPT_DIR/index.js"
fi

log "Node.js environment check completed successfully"
echo "Node.js environment is correctly set up (version $NODE_VERSION)"
echo "Content fetcher is ready to use"
exit 0 