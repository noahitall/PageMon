# Swift-Only Content Fetcher for PageMon

## Overview

PageMon supports two methods for extracting web content:

1. **Swift-only Content Fetcher**: Uses native Swift networking with `URLSession` to fetch HTML content and **SwiftSoup** for HTML parsing and CSS selector-based content extraction.

2. **PageQueryServer Integration**: Connects to a local or remote server that handles content extraction, supporting both static HTML and JavaScript-rendered content.

## Features

### Swift-only Content Fetcher

- **Native Swift Implementation**: No Node.js or JavaScript dependencies required
- **Pure Swift Networking**: Uses URLSession for fetching web content
- **SwiftSoup Integration**: Provides robust HTML parsing with CSS selector support
- **Comprehensive Logging**: Detailed logs to help diagnose issues
- **Support for Multiple Selector Types**: Works with standard CSS selectors including:
  - Tag selectors (`h1`, `p`, `div`)
  - ID selectors (`#header`, `#main`)
  - Class selectors (`.title`, `.content`)
  - Compound selectors (`div.container p`)
  - Attribute selectors (`[href]`, `[src='image.jpg']`)

### PageQueryServer Integration

- **Support for JavaScript Rendering**: Can extract content from JavaScript-rendered websites
- **Centralized Content Extraction**: Single server handles requests from multiple widgets
- **Multiple Result Support**: Can return either the first matching element or all matches
- **API Key Authentication**: Optional security for server requests
- **Consistent Results**: Ensures all widgets use the same extraction logic
- **JavaScript Wait Options**: Fine-grained control over page loading and rendering:
  - Load state waiting (load, domcontentloaded, networkidle)
  - Wait for specific elements to appear before extracting content
  - Additional waiting time for complete rendering

## Limitations

### Swift-only Content Fetcher

- **No JavaScript Rendering**: Cannot extract content from sites that render content using JavaScript
- **Static Content Only**: Only works with pre-rendered HTML content
- **Limited to CSS Selectors**: Uses SwiftSoup's implementation of CSS selectors

### PageQueryServer Integration

- **External Dependency**: Requires running the PageQueryServer
- **Network Access**: Requires network permission to connect to the server
- **Additional Setup**: Server must be configured and running

## Usage

### Swift-only Content Fetcher

To use the Swift-only content fetcher, configure your widget with:

1. The target URL
2. A CSS selector for the content you want to extract
3. Set `useJavaScript` to `false`
4. Set `useServer` to `false`

### PageQueryServer Integration

To use the PageQueryServer, configure your widget with:

1. The target URL
2. A CSS selector for the content you want to extract
3. Set `useServer` to `true`
4. Configure `serverURL` (default: http://127.0.0.1:5000)
5. Set `apiKey` if your server requires authentication
6. Choose whether to fetch all matches (`fetchAllMatches` setting)
7. Set `useJavaScript` based on whether the content requires JavaScript rendering

### JavaScript Wait Options

For complex JavaScript applications that require more time to fully render:

1. Enable JavaScript rendering (`useJavaScript` = true)
2. Enable wait options (`enableWaitOptions` = true)
3. Configure wait parameters:
   - Load State: Choose between "load", "domcontentloaded", or "networkidle"
   - Wait for Selector: Enter a CSS selector for an element that appears when content is ready
   - Additional Wait Time: Specify extra seconds to wait after page load (0-10)

These options allow fine-tuning for websites that use complex JavaScript frameworks or have delayed content loading.

## Example Selectors

Here are some examples of CSS selectors that you can use:

- `h1` - Select the first h1 element
- `#header` - Select element with ID "header"
- `.title` - Select elements with class "title"
- `article p` - Select paragraphs inside article elements
- `div.content > p:first-child` - Select the first paragraph that is a direct child of div with class "content"
- `img[alt]` - Select images with alt attribute
- `a[href^="https"]` - Select links that start with "https"

## PageQueryServer Configuration

The PageQueryServer accepts POST requests with the following JSON structure:

```json
{
  "url": "https://example.com",
  "selector": "h1",
  "timeout": 45,
  "first_only": true,
  "render_js": false,
  "wait_for": {
    "load_state": "load",
    "wait_for_selector": ".some-indicator-element",
    "wait_time": 2
  }
}
```

The server returns JSON responses in this format:

```json
{
  "results": [
    {
      "html": "<h1>Page Title</h1>",
      "text": "Page Title"
    }
  ]
}
```

To set up the PageQueryServer, follow the instructions in the server's documentation.

## Troubleshooting

If you're not getting the expected content:

1. Check that your CSS selector is correct using browser dev tools
2. Verify that the content is present in the HTML source (View Source in browser)
3. For dynamic content that requires JavaScript, enable both `useServer` and `useJavaScript`
4. Check the server logs if using PageQueryServer

For JavaScript-heavy sites:
1. Enable wait options to give the page more time to render
2. For single-page applications, use "networkidle" as load state
3. Find a reliable indicator element that appears after content loads
4. Increase additional wait time for complex animations or delayed content

For server connection issues:
1. Verify the server is running at the configured URL
2. Check that the API key is correct if authentication is enabled
3. Make sure your network allows connections to the server

## Future Improvements

- Enhanced error reporting from the server
- Support for custom HTTP headers in server requests
- Caching integration to reduce server load
- Support for server-side content transformation and filtering 