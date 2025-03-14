#!/usr/bin/env node

/**
 * Direct Content Fetcher for PageMon
 * 
 * This script provides direct content fetching functionality without relying on
 * external process execution. It can be used as an alternative to the regular
 * index.js script when there are issues with process execution in the widget.
 * 
 * Usage:
 *   node direct-fetch.js --url="https://example.com" --selector="h1" [--useJavaScript]
 */

const puppeteer = require('puppeteer');
const cheerio = require('cheerio');
const minimist = require('minimist');
const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

// Parse command line arguments
const argv = minimist(process.argv.slice(2), {
  boolean: ['useJavaScript', 'debug'],
  default: { useJavaScript: false, debug: false },
  alias: { u: 'url', s: 'selector', j: 'useJavaScript', d: 'debug' }
});

// Log execution environment for diagnostics
if (argv.debug) {
  console.error(`[DEBUG] Process Environment:`);
  console.error(`[DEBUG] - Node.js version: ${process.version}`);
  console.error(`[DEBUG] - Process ID: ${process.pid}`);
  console.error(`[DEBUG] - Current directory: ${process.cwd()}`);
  console.error(`[DEBUG] - Script path: ${__filename}`);
  console.error(`[DEBUG] - Arguments: ${JSON.stringify(argv)}`);
  
  // Create a debug log file
  const logDir = '/tmp/PageMonLogs';
  try {
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }
    const logFile = path.join(logDir, `direct-fetch-${Date.now()}.log`);
    fs.writeFileSync(logFile, `Direct fetch started at ${new Date().toISOString()}\nArguments: ${JSON.stringify(argv)}\n`);
    console.error(`[DEBUG] Logging to: ${logFile}`);
  } catch (err) {
    console.error(`[DEBUG] Error creating log file: ${err.message}`);
  }
}

// Validate required arguments
const { url, selector } = argv;
if (!url || !selector) {
  const result = {
    content: '',
    error: 'Missing required parameters (url and selector)',
    date: new Date().toISOString()
  };
  console.log(JSON.stringify(result));
  process.exit(1);
}

// Function to fetch content without JavaScript
async function fetchWithoutJavaScript(url, selector) {
  return new Promise((resolve) => {
    try {
      // Select appropriate library based on URL
      const lib = url.startsWith('https') ? https : http;
      if (argv.debug) console.error(`[DEBUG] Using ${url.startsWith('https') ? 'HTTPS' : 'HTTP'} library`);
      
      // Set a timeout for the request
      const timeout = setTimeout(() => {
        if (argv.debug) console.error(`[DEBUG] Request timed out after 25 seconds`);
        resolve({
          content: '',
          error: 'Request timed out after 25 seconds',
          date: new Date().toISOString()
        });
      }, 25000);
      
      // Make the request
      if (argv.debug) console.error(`[DEBUG] Making HTTP request to ${url}`);
      const req = lib.get(url, (res) => {
        if (argv.debug) console.error(`[DEBUG] Received response with status code: ${res.statusCode}`);
        
        // Check status code
        if (res.statusCode < 200 || res.statusCode >= 300) {
          clearTimeout(timeout);
          if (argv.debug) console.error(`[DEBUG] HTTP error: ${res.statusCode}`);
          resolve({
            content: '',
            error: `HTTP error: ${res.statusCode}`,
            date: new Date().toISOString()
          });
          return;
        }
        
        let data = '';
        
        // Collect data chunks
        res.on('data', (chunk) => {
          data += chunk;
        });
        
        // Process the complete response
        res.on('end', () => {
          clearTimeout(timeout);
          if (argv.debug) console.error(`[DEBUG] Received complete response, size: ${data.length} bytes`);
          
          try {
            // Load HTML into Cheerio
            if (argv.debug) console.error(`[DEBUG] Parsing HTML with Cheerio`);
            const $ = cheerio.load(data);
            
            // Check if selector exists
            if (argv.debug) console.error(`[DEBUG] Checking if selector exists: ${selector}`);
            if ($(selector).length === 0) {
              // Get a preview of the body text
              const bodyText = $('body').text().trim();
              const preview = bodyText.substring(0, 100) + '...';
              
              if (argv.debug) console.error(`[DEBUG] Selector not found`);
              resolve({
                content: `No content found matching '${selector}'. Page preview: ${preview}`,
                error: null,
                date: new Date().toISOString()
              });
              return;
            }
            
            // Process based on element type
            if (argv.debug) console.error(`[DEBUG] Selector found, extracting content`);
            const element = $(selector).first();
            let content = '';
            
            // Handle image
            if (selector.toLowerCase().includes('img') || element.is('img')) {
              if (argv.debug) console.error(`[DEBUG] Element is an image`);
              content = element.attr('src') || '';
            } 
            // Handle link
            else if (element.is('a')) {
              if (argv.debug) console.error(`[DEBUG] Element is a link`);
              content = `${element.text()} (${element.attr('href')})`;
            } 
            // Handle element with children
            else if (element.children().length > 0 && !selector.includes(':text')) {
              if (argv.debug) console.error(`[DEBUG] Element has children`);
              content = element.html();
            } 
            // Default to text
            else {
              if (argv.debug) console.error(`[DEBUG] Extracting text content`);
              content = element.text();
            }
            
            if (argv.debug) console.error(`[DEBUG] Content extracted, length: ${content.length}`);
            resolve({
              content: content.trim(),
              error: null,
              date: new Date().toISOString()
            });
          } catch (error) {
            console.error(`[ERROR] HTML parsing error: ${error.message}`);
            resolve({
              content: '',
              error: `HTML parsing error: ${error.message}`,
              date: new Date().toISOString()
            });
          }
        });
      });
      
      // Handle request errors
      req.on('error', (error) => {
        clearTimeout(timeout);
        console.error(`[ERROR] Request error: ${error.message}`);
        resolve({
          content: '',
          error: `Request error: ${error.message}`,
          date: new Date().toISOString()
        });
      });
      
      req.end();
    } catch (error) {
      console.error(`[ERROR] Unexpected error in fetchWithoutJavaScript: ${error.message}`);
      resolve({
        content: '',
        error: `Unexpected error: ${error.message}`,
        date: new Date().toISOString()
      });
    }
  });
}

// Function to fetch content with JavaScript using Puppeteer
async function fetchWithJavaScript(url, selector) {
  let browser = null;
  
  try {
    if (argv.debug) console.error(`[DEBUG] Launching Puppeteer browser`);
    // Launch a headless browser
    browser = await puppeteer.launch({
      headless: "new",
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
    });
    
    if (argv.debug) console.error(`[DEBUG] Opening new page`);
    // Open a new page
    const page = await browser.newPage();
    
    // Set a reasonable timeout
    await page.setDefaultNavigationTimeout(25000);
    
    // Set a realistic user agent
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36');
    
    if (argv.debug) console.error(`[DEBUG] Navigating to URL: ${url}`);
    // Navigate to the URL
    await page.goto(url, { waitUntil: 'networkidle2' });
    
    if (argv.debug) console.error(`[DEBUG] Page loaded, waiting for additional JavaScript execution`);
    // Wait a bit for any additional JavaScript to run (using evaluate with setTimeout)
    await page.evaluate(() => new Promise(resolve => setTimeout(resolve, 2000)));
    
    if (argv.debug) console.error(`[DEBUG] Checking if selector exists: ${selector}`);
    // Check if the selector exists
    const elementExists = await page.evaluate((sel) => {
      return document.querySelector(sel) !== null;
    }, selector);
    
    if (!elementExists) {
      if (argv.debug) console.error(`[DEBUG] Selector not found`);
      // Get page preview if selector not found
      const preview = await page.evaluate(() => {
        const body = document.body.innerText || '';
        return body.substring(0, 100) + '...';
      });
      
      return {
        content: `No content found matching '${selector}'. Page preview: ${preview}`,
        error: null,
        date: new Date().toISOString()
      };
    }
    
    if (argv.debug) console.error(`[DEBUG] Selector found, extracting content`);
    // Extract the content based on the selector
    const content = await page.evaluate((sel) => {
      const element = document.querySelector(sel);
      
      // If it's an image
      if (element.tagName === 'IMG') {
        return element.src;
      }
      
      // If it's a link
      if (element.tagName === 'A') {
        return `${element.textContent} (${element.href})`;
      }
      
      // If element has children and isn't a special selector
      if (element.children.length > 0 && !sel.includes(':text')) {
        return element.innerHTML;
      }
      
      // Default to text content
      return element.textContent;
    }, selector);
    
    if (argv.debug) console.error(`[DEBUG] Content extracted, length: ${content.length}`);
    return {
      content: content.trim(),
      error: null,
      date: new Date().toISOString()
    };
  } catch (error) {
    console.error(`[ERROR] JavaScript rendering error: ${error.message}`);
    return {
      content: '',
      error: `JavaScript rendering error: ${error.message}`,
      date: new Date().toISOString()
    };
  } finally {
    // Ensure browser is closed
    if (browser) {
      if (argv.debug) console.error(`[DEBUG] Closing browser`);
      await browser.close();
    }
  }
}

// Main function to select the appropriate method and fetch content
async function main() {
  try {
    // Choose the appropriate method based on JavaScript flag
    if (argv.debug) console.error(`[DEBUG] Using ${argv.useJavaScript ? 'JavaScript' : 'non-JavaScript'} approach`);
    const result = argv.useJavaScript 
      ? await fetchWithJavaScript(url, selector)
      : await fetchWithoutJavaScript(url, selector);
    
    // Ensure the result is valid JSON
    try {
      // Test JSON stringify/parse round trip
      const jsonString = JSON.stringify(result);
      JSON.parse(jsonString); // This will throw if there's an issue
      if (argv.debug) console.error(`[DEBUG] Result is valid JSON`);
    } catch (jsonError) {
      console.error(`[ERROR] Result is not valid JSON: ${jsonError.message}`);
      // If the content has invalid JSON characters, sanitize it
      if (result.content) {
        if (argv.debug) console.error(`[DEBUG] Sanitizing content to ensure valid JSON`);
        // Replace or remove problematic characters
        result.content = result.content
          .replace(/[\u0000-\u001F\u007F-\u009F]/g, '') // Remove control characters
          .replace(/\\/g, '\\\\') // Escape backslashes
          .replace(/"/g, '\\"');  // Escape quotes
      }
    }
    
    // Output as JSON
    const outputJson = JSON.stringify(result);
    if (argv.debug) console.error(`[DEBUG] Outputting final JSON result`);
    console.log(outputJson);
  } catch (error) {
    console.error(`[ERROR] Unexpected error in main function: ${error.message}`);
    const errorResult = {
      content: '',
      error: `Unexpected error: ${error.message}`,
      date: new Date().toISOString()
    };
    console.log(JSON.stringify(errorResult));
  }
}

// Execute the main function
if (argv.debug) console.error(`[DEBUG] Starting direct-fetch.js`);
main().catch(error => {
  console.error(`[ERROR] Unhandled error: ${error.message}`);
  const errorResult = {
    content: '',
    error: `Unhandled error: ${error.message}`,
    date: new Date().toISOString()
  };
  console.log(JSON.stringify(errorResult));
}); 