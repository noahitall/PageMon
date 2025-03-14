#!/usr/bin/env node

/**
 * Debug helper for PageContentFetcher output format
 * 
 * This script executes the index.js fetcher and examines its output format
 * to diagnose JSON parsing issues in the Swift widget.
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// URL and selector to test with
const TEST_URL = "https://example.com";
const TEST_SELECTOR = "h1";
const USE_JS = false;

// Path to the index.js script
const indexPath = path.join(__dirname, 'index.js');

console.log(`Testing fetcher with URL: ${TEST_URL}, selector: ${TEST_SELECTOR}`);
console.log(`Script path: ${indexPath}`);

// Check if index.js exists
if (!fs.existsSync(indexPath)) {
  console.error(`Script not found: ${indexPath}`);
  process.exit(1);
}

// Build arguments for the main script
const args = [
  indexPath,
  `--url=${TEST_URL}`,
  `--selector=${TEST_SELECTOR}`,
  '--debug'
];

if (USE_JS) {
  args.push('--useJavaScript');
}

console.log(`Running command: node ${args.join(' ')}`);

// Spawn the Node.js process
const childProcess = spawn('node', args);

let stdout = '';
let stderr = '';

// Collect stdout
childProcess.stdout.on('data', (data) => {
  const chunk = data.toString();
  stdout += chunk;
  console.log("STDOUT CHUNK:", chunk);
});

// Collect stderr
childProcess.stderr.on('data', (data) => {
  const chunk = data.toString();
  stderr += chunk;
  console.log("STDERR CHUNK:", chunk);
});

// Handle process completion
childProcess.on('close', (code) => {
  console.log(`Process completed with code ${code}`);
  
  if (code !== 0) {
    console.error("Process failed", stderr);
    process.exit(code);
  }
  
  console.log("===== STDOUT ANALYSIS =====");
  console.log(`Raw output length: ${stdout.length}`);
  
  const trimmedOutput = stdout.trim();
  console.log(`Trimmed output length: ${trimmedOutput.length}`);
  
  try {
    // Try to parse the JSON output
    const result = JSON.parse(trimmedOutput);
    console.log("Successfully parsed JSON:");
    console.log(JSON.stringify(result, null, 2));
    console.log("JSON structure:");
    console.log(Object.keys(result));
    
    // Check if all expected fields are present
    if (!result.hasOwnProperty('content')) {
      console.warn("Missing 'content' field in response");
    }
    if (!result.hasOwnProperty('date')) {
      console.warn("Missing 'date' field in response");
    }
  } catch (error) {
    console.error("Failed to parse JSON:", error.message);
    console.log("Output:", stdout);
    
    // Try to determine what's wrong with the JSON
    let jsonLines = 0;
    const lines = stdout.split('\n');
    for (let i = 0; i < lines.length; i++) {
      try {
        const line = lines[i].trim();
        if (line) {
          JSON.parse(line);
          console.log(`Line ${i+1} is valid JSON`);
          jsonLines++;
        }
      } catch (e) {
        console.log(`Line ${i+1} is not valid JSON: ${e.message}`);
      }
    }
    
    if (jsonLines > 0) {
      console.log(`Found ${jsonLines} valid JSON lines in output`);
    }
  }
});

// Handle unexpected errors
childProcess.on('error', (error) => {
  console.error("Failed to start process", error);
  process.exit(1);
}); 