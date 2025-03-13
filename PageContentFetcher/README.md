# Page Content Fetcher

A Node.js tool for fetching content from websites using CSS selectors, with optional JavaScript rendering support.

## Overview

This tool provides a reliable way to extract content from websites, even those that require JavaScript to render their content. It uses:

- **Node.js** for the core functionality
- **Puppeteer** (headless Chrome) for JavaScript rendering
- **Cheerio** for non-JavaScript HTML parsing

## Installation

1. Ensure Node.js is installed on your system (version 14 or higher)
2. Install the dependencies:

```bash
cd PageContentFetcher
npm install
```

3. Make the script executable:

```bash
chmod +x index.js
```

## Usage

### Command Line

The simplest way to use this tool is directly with Node.js:

```bash
node index.js --url="https://example.com" --selector=".main-content" [--useJavaScript]
```

Or if you made the script executable:

```bash
./index.js --url="https://example.com" --selector=".main-content" [--useJavaScript]
```

Parameters:
- `--url`: The URL of the website to fetch (required)
- `--selector`: The CSS selector to extract content (required)
- `--useJavaScript`: Add this flag to enable JavaScript rendering (optional)

### Global Installation

You can also install this tool globally:

```bash
npm install -g .
fetch-content --url="https://example.com" --selector=".main-content"
```

### Output

The tool outputs JSON that can be parsed by other applications:

```json
{
  "content": "Extracted content will appear here",
  "error": null,
  "date": "2023-05-20T14:30:45.123Z"
}
```

## Integration with Swift Widget

This tool is designed to be called from the PageMon widget. The widget executes the Node.js script and parses the JSON response.

### Path Configuration

Make sure to update the script path in `PageWidget.swift` to match your installation location:

```swift
let scriptPath = "/path/to/PageContentFetcher/index.js"
```

## How It Works

1. When JavaScript is disabled (default):
   - Uses Cheerio to parse the HTML directly
   - Faster and uses less resources

2. When JavaScript is enabled:
   - Uses Puppeteer (headless Chrome) to render the page
   - Waits for the page to be fully loaded
   - Extracts content after JavaScript execution
   - More resource-intensive but works with modern web apps

## Troubleshooting

- **Permission Denied**: Make sure the script is executable: `chmod +x index.js`
- **Missing Dependencies**: Run `npm install` to ensure all dependencies are installed
- **Timeout Issues**: For large pages, you may need to increase the timeout in the script
- **Puppeteer Issues**: If you encounter problems with Puppeteer, you might need to install additional dependencies depending on your OS 