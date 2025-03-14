#!/bin/bash
# diagnose-widget.sh - Diagnostics script for the PageMon widget
# This script helps diagnose issues with the PageMon content fetcher
# Run this script when your widget is not working properly

set -e

# Setup log directory
LOG_DIR="/tmp/PageMonLogs"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/diagnose-$(date +%Y%m%d-%H%M%S).log"

echo "PageMon Widget Diagnostics" | tee -a "$LOGFILE"
echo "=========================" | tee -a "$LOGFILE"
echo "Date: $(date)" | tee -a "$LOGFILE"
echo "Hostname: $(hostname)" | tee -a "$LOGFILE"
echo "User: $(whoami)" | tee -a "$LOGFILE"
echo "" | tee -a "$LOGFILE"

# Function to log messages
log() {
  echo "$1" | tee -a "$LOGFILE"
}

# Check OS version
log "Checking OS version..."
OS_VERSION=$(sw_vers -productVersion)
log "macOS Version: $OS_VERSION"
echo "" | tee -a "$LOGFILE"

# Check Node.js installation
log "Checking Node.js installation..."
if command -v node &> /dev/null; then
  NODE_VERSION=$(node --version)
  log "Node.js is installed: $NODE_VERSION"
  NODE_PATH=$(which node)
  log "Node.js path: $NODE_PATH"
else
  log "ERROR: Node.js is not installed or not in PATH"
  log "Please install Node.js from https://nodejs.org/"
fi
echo "" | tee -a "$LOGFILE"

# Check npm installation
log "Checking npm installation..."
if command -v npm &> /dev/null; then
  NPM_VERSION=$(npm --version)
  log "npm is installed: $NPM_VERSION"
else
  log "WARNING: npm is not installed or not in PATH"
fi
echo "" | tee -a "$LOGFILE"

# Check PATH environment variable
log "Checking PATH environment variable..."
log "PATH: $PATH"
echo "" | tee -a "$LOGFILE"

# Check for content fetcher installation
log "Checking for PageMon content fetcher installations..."

POSSIBLE_LOCATIONS=(
  "$HOME/Applications/PageMon/PageContentFetcher"
  "/Applications/PageMon/PageContentFetcher"
  "/usr/local/lib/PageMon/PageContentFetcher"
  "$(dirname "$0")"
)

FOUND_INSTALLATION=false

for loc in "${POSSIBLE_LOCATIONS[@]}"; do
  if [ -d "$loc" ]; then
    log "Found installation at: $loc"
    
    # Check for direct-fetch.js
    if [ -f "$loc/direct-fetch.js" ]; then
      log "  direct-fetch.js: FOUND"
      if [ -x "$loc/direct-fetch.js" ]; then
        log "  direct-fetch.js is executable ✓"
      else
        log "  WARNING: direct-fetch.js is not executable"
        log "  Run: chmod +x \"$loc/direct-fetch.js\""
      fi
    else
      log "  direct-fetch.js: NOT FOUND"
    fi
    
    # Check for index.js
    if [ -f "$loc/index.js" ]; then
      log "  index.js: FOUND"
      if [ -x "$loc/index.js" ]; then
        log "  index.js is executable ✓"
      else
        log "  WARNING: index.js is not executable"
        log "  Run: chmod +x \"$loc/index.js\""
      fi
    else
      log "  index.js: NOT FOUND"
    fi
    
    # Check package.json
    if [ -f "$loc/package.json" ]; then
      log "  package.json: FOUND"
    else
      log "  WARNING: package.json NOT FOUND"
    fi
    
    # Check for node_modules
    if [ -d "$loc/node_modules" ]; then
      log "  node_modules: FOUND"
      
      # Check for puppeteer
      if [ -d "$loc/node_modules/puppeteer" ]; then
        log "  puppeteer: FOUND"
      else
        log "  WARNING: puppeteer NOT FOUND"
        log "  Run: cd \"$loc\" && npm install"
      fi
      
      # Check for cheerio
      if [ -d "$loc/node_modules/cheerio" ]; then
        log "  cheerio: FOUND"
      else
        log "  WARNING: cheerio NOT FOUND"
        log "  Run: cd \"$loc\" && npm install"
      fi
    else
      log "  WARNING: node_modules NOT FOUND"
      log "  Run: cd \"$loc\" && npm install"
    fi
    
    FOUND_INSTALLATION=true
    echo "" | tee -a "$LOGFILE"
  fi
done

if [ "$FOUND_INSTALLATION" = false ]; then
  log "ERROR: No PageMon content fetcher installation found!"
  log "Please install PageMon content fetcher using the installer."
  echo "" | tee -a "$LOGFILE"
fi

# Test direct content fetching
log "Testing content fetching..."
for loc in "${POSSIBLE_LOCATIONS[@]}"; do
  if [ -f "$loc/direct-fetch.js" ] && [ -x "$loc/direct-fetch.js" ]; then
    log "Testing direct-fetch.js at $loc..."
    TEST_OUTPUT=$("$loc/direct-fetch.js" --url="https://example.com" --selector="h1" --debug 2>&1)
    TEST_EXIT_CODE=$?
    
    log "Exit code: $TEST_EXIT_CODE"
    log "Output:"
    log "$TEST_OUTPUT"
    
    if [ $TEST_EXIT_CODE -eq 0 ]; then
      log "direct-fetch.js test: SUCCESS ✓"
    else
      log "direct-fetch.js test: FAILED ✗"
    fi
    break
  fi
done
echo "" | tee -a "$LOGFILE"

# Check widget log files
log "Checking widget log files..."
WIDGET_LOGS=$(find "$LOG_DIR" -name "pagemon-*.log" -type f -mtime -1 | sort -r)

if [ -n "$WIDGET_LOGS" ]; then
  log "Found recent widget logs:"
  for log_file in $WIDGET_LOGS; do
    log "  $log_file"
    log "  Last 20 lines:"
    tail -n 20 "$log_file" >> "$LOGFILE"
    log ""
  done
else
  log "No recent widget logs found in $LOG_DIR"
fi

# Summary and next steps
log "Diagnostics Summary"
log "=================="
if command -v node &> /dev/null && [ "$FOUND_INSTALLATION" = true ]; then
  log "✅ Basic requirements for PageMon widget are met."
  log "If you're still experiencing issues, please check the log file for details:"
  log "$LOGFILE"
  log ""
  log "Try testing with a simple example to verify functionality:"
  log "  cd \"/path/to/PageContentFetcher\""
  log "  ./direct-fetch.js --url=\"https://example.com\" --selector=\"h1\" --debug"
else
  log "❌ There are issues with your PageMon installation that need to be resolved."
  log "Please review the log file for details:"
  log "$LOGFILE"
  log ""
  log "Common fixes:"
  log "1. Install Node.js from https://nodejs.org/"
  log "2. Reinstall PageMon content fetcher using the installer"
  log "3. Make sure all scripts are executable:"
  log "   chmod +x /path/to/PageContentFetcher/*.js"
fi

echo "" | tee -a "$LOGFILE"
log "Diagnostics completed. Log saved to: $LOGFILE" 