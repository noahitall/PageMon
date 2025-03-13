#!/usr/bin/env node

/**
 * Test script for PageContentFetcher
 * 
 * Usage:
 *   node test.js --url="https://example.com" --selector="h1" [--useJavaScript]
 * 
 * This script provides detailed testing and logging for the content fetcher.
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const minimist = require('minimist');

// Parse command line arguments
const argv = minimist(process.argv.slice(2), {
  boolean: ['useJavaScript', 'verbose'],
  default: { useJavaScript: false, verbose: true },
  alias: { u: 'url', s: 'selector', j: 'useJavaScript', v: 'verbose' }
});

// Log levels
const LOG_LEVELS = {
  DEBUG: 0,
  INFO: 1,
  WARN: 2,
  ERROR: 3
};

// Current log level
const logLevel = argv.verbose ? LOG_LEVELS.DEBUG : LOG_LEVELS.INFO;

// Logging function
function log(level, message, data = null) {
  if (level >= logLevel) {
    const timestamp = new Date().toISOString();
    const prefix = {
      [LOG_LEVELS.DEBUG]: "🔍 DEBUG",
      [LOG_LEVELS.INFO]: "ℹ️ INFO",
      [LOG_LEVELS.WARN]: "⚠️ WARN",
      [LOG_LEVELS.ERROR]: "❌ ERROR"
    }[level];
    
    console.log(`${prefix} [${timestamp}]: ${message}`);
    if (data) {
      console.log(JSON.stringify(data, null, 2));
    }
  }
}

// Check if required arguments are provided
if (!argv.url || !argv.selector) {
  log(LOG_LEVELS.ERROR, "Missing required parameters");
  console.log("\nUsage:");
  console.log("  node test.js --url=\"https://example.com\" --selector=\"h1\" [--useJavaScript]");
  process.exit(1);
}

// Path to the index.js script
const indexPath = path.join(__dirname, 'index.js');

// Check if index.js exists
if (!fs.existsSync(indexPath)) {
  log(LOG_LEVELS.ERROR, `Script not found: ${indexPath}`);
  process.exit(1);
}

// Log test configuration
log(LOG_LEVELS.INFO, "Starting test with configuration:", {
  url: argv.url,
  selector: argv.selector,
  useJavaScript: argv.useJavaScript
});

// Build arguments for the main script
const args = [
  indexPath,
  `--url=${argv.url}`,
  `--selector=${argv.selector}`
];

if (argv.useJavaScript) {
  args.push('--useJavaScript');
}

log(LOG_LEVELS.DEBUG, "Running command:", { command: 'node', args });

// Spawn the Node.js process
const startTime = Date.now();
const childProcess = spawn('node', args);

let stdout = '';
let stderr = '';

// Collect stdout
childProcess.stdout.on('data', (data) => {
  const chunk = data.toString();
  stdout += chunk;
  log(LOG_LEVELS.DEBUG, "Received stdout chunk:", chunk);
});

// Collect stderr
childProcess.stderr.on('data', (data) => {
  const chunk = data.toString();
  stderr += chunk;
  log(LOG_LEVELS.WARN, "Received stderr:", chunk);
});

// Handle process completion
childProcess.on('close', (code) => {
  const duration = Date.now() - startTime;
  
  log(LOG_LEVELS.INFO, `Process completed with code ${code} in ${duration}ms`);
  
  if (code !== 0) {
    log(LOG_LEVELS.ERROR, "Process failed", { stderr });
    process.exit(code);
  }
  
  try {
    // Try to parse the JSON output
    const result = JSON.parse(stdout);
    log(LOG_LEVELS.INFO, "Successfully parsed JSON response:", result);
    
    // Check for errors in the response
    if (result.error) {
      log(LOG_LEVELS.WARN, "Content fetcher returned an error:", result.error);
    } else {
      log(LOG_LEVELS.INFO, "Content successfully fetched:", {
        contentLength: result.content.length,
        date: result.date
      });
      
      // Show a preview of the content
      log(LOG_LEVELS.INFO, "Content preview:", result.content.substring(0, 100) + (result.content.length > 100 ? '...' : ''));
    }
  } catch (error) {
    log(LOG_LEVELS.ERROR, "Failed to parse JSON response", {
      error: error.message,
      stdout
    });
    process.exit(1);
  }
});

// Handle unexpected errors
childProcess.on('error', (error) => {
  log(LOG_LEVELS.ERROR, "Failed to start process", error);
  process.exit(1);
}); 