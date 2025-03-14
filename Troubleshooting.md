### Widget Shows "No content received from fetcher"

This error indicates that the content fetcher is failing to return any data to the widget.

**Solutions:**

1. **Check if Node.js is available to the widget**:
   The most common cause of this error is that Node.js cannot be found in the widget's environment. Run the symlink fixer script:
   ```bash
   ./PageContentFetcher/fix-node-symlinks.sh
   ```
   This will create symlinks to your Node.js installation in standard locations that the widget can access.

2. **Test with the debug helper**:
   ```bash
   ./debug-fetcher.swift --url="your-url" --selector="your-selector" --verbose
   ```
   This will show exactly what's happening when trying to fetch content.

3. **Check the logs**:
   Look at the log files in your widget container at:
   ```
   ~/Library/Containers/me.noze.PageMon.PageWidget/Data/tmp/PageMonLogs/
   ```
   These logs often show the specific error, such as "node: command not found".

4. **Restart your Mac**:
   Sometimes a full restart is needed for the widget to recognize system changes like new symlinks.

### Swift-Only Content Fetcher

The PageMon widget now uses a pure Swift implementation for content fetching that doesn't require Node.js. This provides a more reliable experience for basic content fetching but has some limitations:

**Benefits:**
- No external dependencies required
- Works within widget sandbox restrictions
- More reliable for static content

**Limitations:**
- **No JavaScript support**: Cannot render JavaScript-driven content
- **Simple selector support**: Only supports basic tag, ID, and class selectors
- **Basic HTML parsing**: May not handle complex HTML perfectly

If your website requires JavaScript to display content, the Swift-only solution won't be able to extract that content. In such cases, you would need to:

1. Install Node.js
2. Run the fix-node-symlinks.sh script 
3. Edit PageWidget.swift to use the Node.js-based fetcher implementation

See the [Swift-Solution.md](Swift-Solution.md) document for more details.

### Widget Shows Content From Wrong Element

If the widget is selecting incorrect content or no content:

1. **Check your selector syntax**: Make sure you're using a supported selector format:
   - Simple tag: `h1`, `p`, `div`
   - ID selector: `#header`, `#main`
   - Class selector: `.title`, `.price`
   
2. **Inspect the website structure**: Use browser developer tools to verify your selector matches the expected element.

3. **Try a more specific selector**: Sometimes a more specific selector can help target the exact content you want.

4. **For complex websites**: If the site has a complex structure or loads content with JavaScript, you may need to revert to the Node.js implementation.

## No content received from fetcher

If your widget displays "No content received from fetcher", check the following:

1. **URL Accessibility**: Make sure the URL is accessible in a browser
2. **Selector Validity**: Verify that your CSS selector is correct
3. **Static Content**: Ensure the content is present in the HTML source (View Source in browser)
4. **Server Connection**: If using PageQueryServer, verify the server is running

### Using the Swift-based Fetcher with SwiftSoup

PageMon now includes a native Swift solution using SwiftSoup that offers robust HTML parsing with CSS selector support. This solution works best for static websites where content is present in the initial HTML.

**Features of the SwiftSoup solution:**
- Supports standard CSS selectors similar to querySelector in JavaScript
- Works without any external dependencies
- Can extract various content types (text, attributes, HTML)

**Example selectors that work with SwiftSoup:**
- `div.content p` - Select paragraphs inside a div with class "content"
- `#main article h2` - Select h2 headings inside an article within the element with ID "main"
- `a[href^="https"]` - Select links that start with "https"
- `table tr:nth-child(2) td` - Select cells from the second row of a table

**To use SwiftSoup in your widget:**
1. Enter the website URL
2. Enter your CSS selector using the formats shown above
3. Set "Use JavaScript" to OFF (since SwiftSoup works with static HTML)
4. Set "Use Server" to OFF

### Using the PageQueryServer

For more advanced content extraction, especially from JavaScript-rendered websites, PageMon now supports connection to a PageQueryServer.

**To use the PageQueryServer:**
1. Make sure the PageQueryServer is running (default: http://127.0.0.1:5000)
2. In the widget configuration:
   - Enter the website URL
   - Enter your CSS selector
   - Set "Use Server" to ON
   - Configure the server URL
   - Add API key if required by your server
   - Choose whether to fetch all matches
   - Set "Use JavaScript" to ON if the content requires JavaScript rendering

**Common PageQueryServer issues:**

- **Cannot connect to server**:
  - Verify the server is running
  - Check that the server URL is correct
  - Ensure network connectivity between the widget and server

- **Authentication failed**:
  - Verify the API key is correct
  - Check the server logs for authentication errors

- **No content found**:
  - Verify the selector works with the server's parsing engine
  - Check server logs for detailed error messages
  - Try using the server's test interface if available

- **JavaScript content not rendering**:
  - Ensure the server has a browser engine installed
  - Verify that "render_js" functionality is enabled on the server
  - Check if the website uses anti-bot measures that block the server

### For JavaScript-rendered Content

If the website requires JavaScript to render content (often the case with modern web apps):

1. Use the PageQueryServer approach:
   - Set "Use Server" to ON
   - Configure the server URL
   - Set "Use JavaScript" to ON

2. Or, if not using the server:
   - Make sure Node.js is installed and properly configured
   - Set "Use JavaScript" to ON in widget settings
   - Check the logs for any Node.js execution errors 