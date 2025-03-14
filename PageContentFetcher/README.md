# PageMon Content Fetcher

This is the content fetching module for the PageMon widget. It allows the widget to extract content from websites using CSS selectors, with optional JavaScript rendering support for dynamic websites.

## Installation

1. Ensure you have Node.js installed on your system. You can download it from [nodejs.org](https://nodejs.org/).

2. Install the required dependencies:
   ```bash
   cd PageContentFetcher
   npm install
   ```

3. Make the scripts executable:
   ```bash
   chmod +x index.js
   chmod +x test.js
   chmod +x ensure-node.sh
   chmod +x setup-and-test.sh
   ```

4. Run the setup and test script to verify everything is working:
   ```bash
   ./setup-and-test.sh
   ```

## Usage

### Running the Content Fetcher Directly

You can run the content fetcher directly from the command line:

```bash
./index.js --url="https://example.com" --selector="#content" [--useJavaScript] [--debug]
```

Parameters:
- `--url`: The URL of the website to fetch content from (required)
- `--selector`: The CSS selector to extract content from (required)
- `--useJavaScript`: Enable JavaScript rendering for dynamic websites (optional)
- `--debug`: Show detailed debug output (optional)

### Running Tests

To test the content fetcher with more detailed output:

```bash
./test.js --url="https://example.com" --selector="h1" [--useJavaScript] [--verbose]
```

The test script provides more detailed information about the execution and results.

## Integration with the Widget

The PageMon widget uses this content fetcher to extract website content. The integration works as follows:

1. The widget calls `ensure-node.sh` to verify the Node.js environment is properly set up
2. If the check passes, the widget then runs `index.js` with the appropriate parameters
3. The output (in JSON format) is parsed by the widget and displayed

## Troubleshooting

If you encounter issues with the content fetcher or widget:

### "Invalid response format" Error

This error occurs when the widget can't parse the JSON output from the content fetcher.

1. Check the logs in the widget's logfile (path is shown in the error message)
2. Run the test script with the same URL and selector to verify output:
   ```bash
   ./test.js --url="your-url" --selector="your-selector" --verbose
   ```
3. Ensure the output is valid JSON by checking the debug output

### "Node.js not properly configured" Error

This error occurs when the widget can't find or execute Node.js correctly.

1. Verify Node.js is installed and in your PATH:
   ```bash
   node --version
   ```
2. Run the environment check script manually:
   ```bash
   ./ensure-node.sh
   ```
3. Make sure all scripts are executable:
   ```bash
   chmod +x *.js *.sh
   ```

### JavaScript Rendering Issues

If you're having trouble with JavaScript rendering:

1. Verify Puppeteer is installed correctly:
   ```bash
   npm list puppeteer
   ```
2. Try running with the debug flag to see detailed output:
   ```bash
   ./index.js --url="your-url" --selector="your-selector" --useJavaScript --debug
   ```
3. Increase the wait time if the page needs more time to load (edit index.js and increase the timeout value)

### Performance Issues

If the widget is slow to update:

1. Avoid using JavaScript rendering unless necessary (it's much slower)
2. Use more specific CSS selectors to target content efficiently
3. Consider using smaller widgets which require less content

## Logs

Logs from the content fetcher can be found in:
- `/tmp/PageMonLogs` for environment check logs
- The path shown in error messages for widget operation logs

These logs can help diagnose issues with content fetching, JavaScript rendering, and more.

## Advanced Usage

### Using More Complex Selectors

The content fetcher supports full CSS selectors with SwiftSoup:

```
# Basic selectors
h1                  # Select all h1 elements
.class-name         # Select elements with class="class-name"
#id-name            # Select element with id="id-name"

# Combinators
div p               # Select all p elements inside div elements
div > p             # Select all p elements with div as direct parent
div + p             # Select p element directly after div
div ~ p             # Select all p elements after div

# Attribute selectors
[attr]              # Select elements with attr attribute
[attr=value]        # Select elements with attr="value"
[attr^=value]       # Select elements with attr starting with "value"
[attr$=value]       # Select elements with attr ending with "value"
[attr*=value]       # Select elements with attr containing "value"

# Pseudo-classes
:first-child        # Select elements that are first child of parent
:last-child         # Select elements that are last child of parent
:nth-child(n)       # Select elements that are nth child of parent
``` 