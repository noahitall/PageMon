#!/usr/bin/env node

const puppeteer = require('puppeteer');
const cheerio = require('cheerio');
const minimist = require('minimist');
const https = require('https');
const http = require('http');

// Parse command line arguments
const argv = minimist(process.argv.slice(2), {
  boolean: ['useJavaScript', 'debug'],
  default: { useJavaScript: false, debug: false },
  alias: { u: 'url', s: 'selector', j: 'useJavaScript', d: 'debug' }
});

// Debug mode - outputs diagnostic information to stderr
const DEBUG = argv.debug;

// Debug logging function (to stderr to keep stdout clean for JSON output)
function debug(message, data = null) {
  if (DEBUG) {
    const timestamp = new Date().toISOString();
    process.stderr.write(`[DEBUG ${timestamp}] ${message}\n`);
    if (data) {
      process.stderr.write(JSON.stringify(data, null, 2) + '\n');
    }
  }
}

// Error logging function (always outputs to stderr)
function logError(message, error = null) {
  const timestamp = new Date().toISOString();
  process.stderr.write(`[ERROR ${timestamp}] ${message}\n`);
  if (error) {
    process.stderr.write(`${error.stack || error}\n`);
  }
}

debug("Starting with arguments:", argv);

// Validate required arguments
if (!argv.url || !argv.selector) {
  const errorResponse = {
    error: 'Missing required parameters. Usage: npx fetch-content --url URL --selector SELECTOR [--useJavaScript]',
    date: new Date().toISOString()
  };
  console.log(JSON.stringify(errorResponse));
  process.exit(1);
}

// Function to fetch content with JavaScript rendering using Puppeteer
async function fetchWithJavaScript(url, selector) {
  let browser = null;
  debug(`Fetching with JavaScript: ${url}, selector: ${selector}`);
  
  try {
    debug("Launching Puppeteer browser");
    // Launch a headless browser
    browser = await puppeteer.launch({
      headless: "new",
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
    });
    
    debug("Opening new page");
    // Open a new page
    const page = await browser.newPage();
    
    // Set a reasonable timeout
    await page.setDefaultNavigationTimeout(25000);
    
    // Set a realistic user agent
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36');
    
    debug(`Navigating to URL: ${url}`);
    // Navigate to the URL
    await page.goto(url, { waitUntil: 'networkidle2' });
    
    debug("Page loaded, waiting for additional JavaScript execution");
    // Wait a bit for any additional JavaScript to run
    await page.evaluate(() => new Promise(resolve => setTimeout(resolve, 2000)));
    
    debug(`Checking if selector exists: ${selector}`);
    // Check if the selector exists
    const elementExists = await page.evaluate((sel) => {
      return document.querySelector(sel) !== null;
    }, selector);
    
    if (!elementExists) {
      debug("Selector not found, getting page preview");
      // Get page preview if selector not found
      const preview = await page.evaluate(() => {
        const body = document.body.innerText || '';
        return body.substring(0, 100) + '...';
      });
      
      debug("Returning 'not found' response with preview");
      return {
        content: `No content found matching '${selector}'. Page preview: ${preview}`,
        error: null,
        date: new Date().toISOString()
      };
    }
    
    debug("Selector found, extracting content");
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
    
    debug(`Content extracted, length: ${content.length}`);
    return {
      content: content.trim(),
      error: null,
      date: new Date().toISOString()
    };
  } catch (error) {
    logError("Error in JavaScript rendering", error);
    return {
      content: '',
      error: `JavaScript rendering error: ${error.message}`,
      date: new Date().toISOString()
    };
  } finally {
    // Ensure browser is closed
    if (browser) {
      debug("Closing browser");
      await browser.close();
    }
  }
}

// Function to fetch content without JavaScript rendering using Cheerio
async function fetchWithoutJavaScript(url, selector) {
  debug(`Fetching without JavaScript: ${url}, selector: ${selector}`);
  
  return new Promise((resolve) => {
    // Select appropriate library based on URL
    const lib = url.startsWith('https') ? https : http;
    debug(`Using ${url.startsWith('https') ? 'HTTPS' : 'HTTP'} library`);
    
    // Set a timeout for the request
    const timeout = setTimeout(() => {
      debug("Request timed out");
      resolve({
        content: '',
        error: 'Request timed out after 25 seconds',
        date: new Date().toISOString()
      });
    }, 25000);
    
    debug("Making HTTP request");
    // Make the request
    const req = lib.get(url, (res) => {
      debug(`Received response with status code: ${res.statusCode}`);
      
      // Check status code
      if (res.statusCode < 200 || res.statusCode >= 300) {
        clearTimeout(timeout);
        debug(`HTTP error: ${res.statusCode}`);
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
        debug(`Received complete response, size: ${data.length} bytes`);
        
        try {
          // Load HTML into Cheerio
          debug("Parsing HTML with Cheerio");
          const $ = cheerio.load(data);
          
          // Check if selector exists
          debug(`Checking if selector exists: ${selector}`);
          if ($(selector).length === 0) {
            // Get a preview of the body text
            const bodyText = $('body').text().trim();
            const preview = bodyText.substring(0, 100) + '...';
            
            debug("Selector not found, returning preview");
            resolve({
              content: `No content found matching '${selector}'. Page preview: ${preview}`,
              error: null,
              date: new Date().toISOString()
            });
            return;
          }
          
          // Process based on element type
          debug("Selector found, extracting content");
          const element = $(selector).first();
          let content = '';
          
          // Handle image
          if (selector.toLowerCase().includes('img') || element.is('img')) {
            debug("Element is an image, extracting src attribute");
            content = element.attr('src') || '';
          } 
          // Handle link
          else if (element.is('a')) {
            debug("Element is a link, extracting text and href");
            content = `${element.text()} (${element.attr('href')})`;
          } 
          // Handle element with children
          else if (element.children().length > 0 && !selector.includes(':text')) {
            debug("Element has children, extracting HTML");
            content = element.html();
          } 
          // Default to text
          else {
            debug("Extracting text content");
            content = element.text();
          }
          
          debug(`Content extracted, length: ${content.length}`);
          resolve({
            content: content.trim(),
            error: null,
            date: new Date().toISOString()
          });
        } catch (error) {
          logError("HTML parsing error", error);
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
      logError("Request error", error);
      resolve({
        content: '',
        error: `Request error: ${error.message}`,
        date: new Date().toISOString()
      });
    });
    
    req.end();
  });
}

// Main function
async function main() {
  const { url, selector, useJavaScript } = argv;
  debug("Starting main function with params:", { url, selector, useJavaScript });
  
  try {
    // Choose the appropriate method based on JavaScript flag
    debug(`Using ${useJavaScript ? 'JavaScript' : 'non-JavaScript'} approach`);
    const result = useJavaScript 
      ? await fetchWithJavaScript(url, selector)
      : await fetchWithoutJavaScript(url, selector);
    
    // Ensure the result is valid JSON
    try {
      // Test JSON stringify/parse round trip
      const jsonString = JSON.stringify(result);
      JSON.parse(jsonString); // This will throw if there's an issue
      debug("Result is valid JSON");
    } catch (jsonError) {
      logError("Result is not valid JSON", jsonError);
      // If the content has invalid JSON characters, sanitize it
      if (result.content) {
        debug("Sanitizing content to ensure valid JSON");
        // Replace or remove problematic characters
        result.content = result.content
          .replace(/[\u0000-\u001F\u007F-\u009F]/g, '') // Remove control characters
          .replace(/\\/g, '\\\\') // Escape backslashes
          .replace(/"/g, '\\"');  // Escape quotes
      }
    }
    
    // Output as JSON
    const outputJson = JSON.stringify(result);
    debug("Outputting final JSON result");
    console.log(outputJson);
  } catch (error) {
    logError("Unexpected error in main function", error);
    console.error(JSON.stringify({
      content: '',
      error: `Unexpected error: ${error.message}`,
      date: new Date().toISOString()
    }));
    process.exit(1);
  }
}

// Run the main function
main().catch(error => {
  logError("Unhandled error in main function", error);
  process.exit(1);
}); 