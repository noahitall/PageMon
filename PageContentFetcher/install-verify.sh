#!/bin/bash

# PageMon Installation Verification Script
# This script verifies that the PageMon content fetcher is correctly installed
# and that the Node.js environment is properly configured

set -e

# Set terminal colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGS_DIR="/tmp/PageMonLogs"
LOG_FILE="$LOGS_DIR/pagemon-verify.log"

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

echo -e "${BLUE}PageMon Installation Verification${NC}"
log "Starting verification at: $(date)"
log "Script directory: $SCRIPT_DIR"

# Check if we're running from the correct location
if [[ "$SCRIPT_DIR" != *"PageContentFetcher" ]]; then
    log "WARNING: This script is not running from a directory named 'PageContentFetcher'"
    log "Current directory: $SCRIPT_DIR"
    echo -e "${RED}Warning: This script is not running from the expected location.${NC}"
fi

# Check if Node.js is installed and available in PATH
echo "Checking Node.js installation..."
NODE_PATH=$(which node 2>/dev/null || echo "")
if [ -z "$NODE_PATH" ]; then
    log "ERROR: Node.js not found in PATH"
    echo -e "${RED}ERROR: Node.js not found.${NC}"
    echo "Please install Node.js from https://nodejs.org/"
    echo "After installing Node.js, run this script again."
    exit 1
fi

log "Node.js found at: $NODE_PATH"
NODE_VERSION=$(node --version)
log "Node.js version: $NODE_VERSION"
echo -e "Node.js ${GREEN}$NODE_VERSION${NC} found at: $NODE_PATH"

# Check NPM
echo "Checking npm installation..."
NPM_PATH=$(which npm 2>/dev/null || echo "")
if [ -z "$NPM_PATH" ]; then
    log "ERROR: npm not found in PATH"
    echo -e "${RED}ERROR: npm not found.${NC}"
    echo "npm should be installed with Node.js. Please reinstall Node.js."
    exit 1
fi

log "npm found at: $NPM_PATH"
NPM_VERSION=$(npm --version)
log "npm version: $NPM_VERSION"
echo -e "npm ${GREEN}$NPM_VERSION${NC} found at: $NPM_PATH"

# Check if required files exist
echo "Checking required files..."
MISSING_FILES=0

check_file() {
    if [ ! -f "$1" ]; then
        log "ERROR: Required file not found: $1"
        echo -e "${RED}ERROR: Required file not found: $1${NC}"
        MISSING_FILES=$((MISSING_FILES + 1))
    else
        log "File exists: $1"
        if [ "${1##*.}" == "js" ] || [ "${1##*.}" == "sh" ]; then
            if [ ! -x "$1" ]; then
                log "WARNING: File is not executable: $1"
                echo -e "${RED}WARNING: File is not executable: $1${NC}"
                echo "Setting executable permission..."
                chmod +x "$1"
            fi
        fi
    fi
}

check_file "$SCRIPT_DIR/index.js"
check_file "$SCRIPT_DIR/package.json"
check_file "$SCRIPT_DIR/ensure-node.sh"
check_file "$SCRIPT_DIR/test.js"

if [ $MISSING_FILES -gt 0 ]; then
    log "ERROR: $MISSING_FILES required files are missing"
    echo -e "${RED}ERROR: $MISSING_FILES required files are missing${NC}"
    echo "Please reinstall PageMon."
    exit 1
fi

# Check if node_modules exists and install if needed
echo "Checking Node.js dependencies..."
if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
    log "node_modules not found, running npm install"
    echo "Installing Node.js dependencies..."
    cd "$SCRIPT_DIR"
    npm install >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "ERROR: npm install failed"
        echo -e "${RED}ERROR: Failed to install Node.js dependencies${NC}"
        echo "Please check the log file: $LOG_FILE"
        exit 1
    fi
    log "npm install completed successfully"
    echo -e "${GREEN}Dependencies installed successfully${NC}"
else
    log "node_modules directory exists"
    echo -e "${GREEN}Dependencies already installed${NC}"
fi

# Test the content fetcher
echo "Testing content fetcher..."
TEST_OUTPUT=$(cd "$SCRIPT_DIR" && node index.js --url="https://example.com" --selector="h1" 2>>"$LOG_FILE")
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -ne 0 ]; then
    log "ERROR: Content fetcher test failed with exit code $TEST_EXIT_CODE"
    echo -e "${RED}ERROR: Content fetcher test failed${NC}"
    echo "Please check the log file: $LOG_FILE"
    exit 1
fi

# Check if output is valid JSON
echo "$TEST_OUTPUT" | node -e "try { JSON.parse(require('fs').readFileSync(0, 'utf8')); console.log('valid'); } catch(e) { console.error(e); process.exit(1); }" > /dev/null 2>> "$LOG_FILE"
if [ $? -ne 0 ]; then
    log "ERROR: Content fetcher did not produce valid JSON"
    log "Output: $TEST_OUTPUT"
    echo -e "${RED}ERROR: Content fetcher did not produce valid JSON${NC}"
    echo "Please check the log file: $LOG_FILE"
    exit 1
fi

log "Content fetcher test passed"
echo -e "${GREEN}Content fetcher test passed${NC}"

# Display final success message
echo -e "\n${GREEN}✅ PageMon verification completed successfully!${NC}"
echo "The PageMon content fetcher is properly installed and configured."
echo 
echo "You can now configure your widget to use this installation."
echo -e "Path to use in widget configuration: ${BLUE}$SCRIPT_DIR/index.js${NC}"
echo
echo "For troubleshooting, check the log file: $LOG_FILE"

exit 0 