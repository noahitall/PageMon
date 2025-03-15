# PageMon

A macOS widget system for monitoring web content changes. Extract and display content from any website directly on your desktop.

<p align="center">
  <img src="screenshots/preview.png" alt="PageMon Widget Preview" width="600">
</p>

## Features

- **Widget-based monitoring**: Display content from any website as a macOS widget
- **CSS selectors**: Target specific content on websites using standard CSS selectors
- **Multiple widget sizes**: Small, medium, and large widget configurations
- **JavaScript support**: Render JS-heavy websites using [HeadlessDom](https://github.com/noahitall/HeadlessDom)
- **Multiple matches**: Option to display multiple elements matching your selector
- **Wait options**: Advanced controls for handling dynamic websites
- **Error handling**: Clear error messages and guidance for troubleshooting
- **Light & dark mode**: Automatic support for system appearance settings

## Installation

1. Download the latest release from the [Releases](https://github.com/noahitall/PageMon/releases) page
2. Open the DMG file and drag the app to your Applications folder
3. Open the app once to register it with the system
4. Add the widget to your desktop by:
   - Right-clicking on the desktop
   - Selecting "Edit Widgets"
   - Finding "PageMon" in the widget gallery
   - Dragging the widget to your desktop

## JavaScript Support

PageMon supports monitoring JavaScript-rendered websites by integrating with [HeadlessDom](https://github.com/noahitall/HeadlessDom), a headless browser service that can execute JavaScript and extract content.

### Setting Up HeadlessDom

1. Install [HeadlessDom](https://github.com/noahitall/HeadlessDom) using one of the methods:

   **Docker Installation**:
   ```bash
   docker build -t headless-dom .
   docker run -p 127.0.0.1:5000:5000 headless-dom
   ```

   **Native macOS Installation**:
   ```bash
   chmod +x build_installer.sh
   ./build_installer.sh
   # Open the generated installer package
   ```

2. Configure your PageMon widget to use the HeadlessDom server:
   - Enable "Use Server" in the widget configuration
   - Set "Server URL" to `http://127.0.0.1:5000` (or your custom server URL)
   - Enable "Use JavaScript" to activate JavaScript rendering

## Widget Configuration

PageMon offers extensive configuration options:

### Basic Settings

- **Website URL**: The URL of the website to monitor
- **Label**: Custom label to display above the content
- **Query Selector**: CSS selector to target specific content (e.g., `.price`, `#header`, `table tr:first-child`)

### Advanced Options

- **Use JavaScript**: Enable JavaScript rendering for dynamic websites (requires HeadlessDom)
- **Use Server**: Connect to a HeadlessDom server for enhanced capabilities
- **Server URL**: URL of your HeadlessDom instance
- **API Key**: Optional authentication for your HeadlessDom server
- **Fetch All Matches**: Display all elements matching your selector instead of just the first

### JavaScript Wait Options

For complex dynamic websites, fine-tune the wait behavior:

- **Enable Wait Options**: Activate advanced wait options
- **Load State**: Choose between `domcontentloaded`, `load`, or `networkidle`
- **Wait for Selector**: Wait for a specific element to appear before extracting content
- **Additional Wait Time**: Add extra seconds of wait time after the page loads

## CSS Selector Examples

| Target | Selector |
|--------|----------|
| Page title | `h1` or `title` |
| Price on a product page | `.price`, `span.amount` |
| Table data | `table tr:nth-child(2) td:first-child` |
| Navigation links | `nav a` |
| Specific element by ID | `#stock-price` |
| Elements with attributes | `[data-testid="price-value"]` |

## Troubleshooting

### Common Issues

- **No content displayed**: Verify your CSS selector using browser developer tools
- **"JavaScript rendering requires server mode"**: Enable "Use Server" when using JavaScript
- **Connection errors**: Ensure HeadlessDom is running and the URL is correct
- **"No content found"**: Your selector may not match any elements, try a different selector

### Debugging

1. Check if your selector works in browser developer tools
2. Test with simpler selectors first
3. For JavaScript sites, try increasing wait times
4. Check HeadlessDom logs for server-side issues

## License

MIT License

## Acknowledgments

- [HeadlessDom](https://github.com/noahitall/HeadlessDom) for JavaScript rendering capabilities
- [SwiftSoup](https://github.com/scinfu/SwiftSoup) for HTML parsing 