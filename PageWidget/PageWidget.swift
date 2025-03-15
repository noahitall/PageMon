//
//  PageWidget.swift
//  PageWidget
//
//  Created by Noah Zitsman on 3/13/25.
//

import WidgetKit
import SwiftUI
import SwiftSoup

// Content extraction model
struct WebContent {
    var content: String
    var error: String?
    var lastUpdated: Date
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            webContent: WebContent(content: "Loading...", error: nil, lastUpdated: Date())
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // For preview/snapshot purposes, return some sample content
        let sampleContent = "This is sample content that would be extracted from the website."
        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            webContent: WebContent(content: sampleContent, error: nil, lastUpdated: Date())
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // Validate configuration before fetching content
        let configValidation = validateConfiguration(configuration)
        let webContent: WebContent
        
        if let validationError = configValidation {
            // Configuration is invalid, return the error
            webContent = WebContent(
                content: "",
                error: validationError,
                lastUpdated: currentDate
            )
        } else {
            // Configuration is valid, fetch content
            webContent = await fetchWebContent(
                configuration: configuration,
                url: configuration.websiteURL,
                querySelector: configuration.querySelector,
                useJavaScript: configuration.useJavaScript
            )
        }
        
        // Create current entry
        let entry = SimpleEntry(
            date: currentDate,
            configuration: configuration,
            webContent: webContent
        )
        entries.append(entry)
        
        // Schedule next update in 1 hour
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        
        return Timeline(entries: entries, policy: .after(nextUpdateDate))
    }
    
    // Validate the configuration settings
    private func validateConfiguration(_ configuration: ConfigurationAppIntent) -> String? {
        // Validate website URL
        if configuration.websiteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter a website URL"
        }
        
        if !configuration.websiteURL.hasPrefix("http://") && !configuration.websiteURL.hasPrefix("https://") {
            return "Website URL must start with http:// or https://"
        }
        
        guard URL(string: configuration.websiteURL) != nil else {
            return "Invalid website URL format"
        }
        
        // Validate query selector
        if configuration.querySelector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter a CSS selector"
        }
        
        // Validate server settings
        if configuration.useServer {
            // Check server URL
            if configuration.serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Server URL cannot be empty when using server mode"
            }
            
            if !configuration.serverURL.hasPrefix("http://") && !configuration.serverURL.hasPrefix("https://") {
                return "Server URL must start with http:// or https://"
            }
            
            guard URL(string: configuration.serverURL) != nil else {
                return "Invalid server URL format"
            }
            
            // Validate wait options if enabled
            if configuration.enableWaitOptions {
                // Wait options require JavaScript rendering
                if !configuration.useJavaScript {
                    return "Wait options require JavaScript rendering to be enabled"
                }
                
                // Validate load state
                if !configuration.loadState.isEmpty {
                    let validLoadStates = ["domcontentloaded", "load", "networkidle"]
                    if !validLoadStates.contains(configuration.loadState) {
                        return "Load state must be 'domcontentloaded', 'load', or 'networkidle'"
                    }
                }
                
                // Validate wait for selector - only check if non-empty
                if !configuration.waitForSelector.isEmpty {
                    // Ensure it's not just whitespace
                    if configuration.waitForSelector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        return "Wait for selector cannot be only whitespace"
                    }
                    
                    // Check for common CSS selector errors - basic validation
                    let selector = configuration.waitForSelector.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let firstChar = selector.first, firstChar.isNumber {
                        return "Wait for selector cannot start with a number (use a valid CSS selector)"
                    }
                    
                    // Ensure it's not just a number
                    if Double(selector) != nil || Int(selector) != nil {
                        return "Wait for selector must be a CSS selector string, not a number"
                    }
                }
                
                // Validate wait time
                if configuration.additionalWaitTime < 0 {
                    return "Additional wait time cannot be negative"
                }
                
                if configuration.additionalWaitTime > 10 {
                    return "Additional wait time cannot exceed 10 seconds"
                }
                
                // Ensure at least one wait option is specified
                if configuration.loadState.isEmpty && 
                   configuration.waitForSelector.isEmpty && 
                   configuration.additionalWaitTime <= 0 {
                    return "At least one wait option must be specified when wait options are enabled"
                }
            }
        } else {
            // If not using server but JavaScript is enabled
            if configuration.useJavaScript {
                return "JavaScript rendering requires server mode to be enabled. Please enable 'Use Server' or disable 'Use JavaScript'."
            }
            
            // If fetchAllMatches is enabled but not using server
            if configuration.fetchAllMatches {
                return "'Fetch All Matches' requires server mode to be enabled. Please enable 'Use Server'."
            }
            
            // If wait options are enabled but not using server
            if configuration.enableWaitOptions {
                return "Wait options require server mode to be enabled. Please enable 'Use Server'."
            }
        }
        
        // All checks passed
        return nil
    }
    
    private func fetchWebContent(configuration: ConfigurationAppIntent, url: String, querySelector: String, useJavaScript: Bool) async -> WebContent {
        // Setup logging
        let logsDir = FileManager.default.temporaryDirectory.appendingPathComponent("PageMonLogs")
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        let logFile = logsDir.appendingPathComponent("swift-fetcher-\(Date().timeIntervalSince1970).log")
        
        // Log function
        func log(_ message: String) {
            // Append to log file
            if let data = (message + "\n").data(using: .utf8) {
                if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try? fileHandle.close()
                } else {
                    try? data.write(to: logFile, options: .atomic)
                }
            }
        }
        
        // Start logging
        log("Starting content fetch at: \(Date())")
        log("URL: \(url)")
        log("Selector: \(querySelector)")
        log("JavaScript Requested: \(useJavaScript)")
        log("Server Mode: \(configuration.useServer)")
        if configuration.useServer {
            log("Server URL: \(configuration.serverURL)")
            log("Fetch All Matches: \(configuration.fetchAllMatches)")
            
            if configuration.useJavaScript && configuration.enableWaitOptions {
                log("JavaScript Wait Options Enabled: true")
                if !configuration.loadState.isEmpty {
                    log("Load State: \(configuration.loadState)")
                }
                if !configuration.waitForSelector.isEmpty {
                    log("Wait For Selector: \(configuration.waitForSelector)")
                }
                if configuration.additionalWaitTime > 0 {
                    log("Additional Wait Time: \(configuration.additionalWaitTime) seconds")
                }
            }
        }
        
        // Check that URL is valid
        guard let urlObj = URL(string: url) else {
            log("Error: Invalid URL format")
            return WebContent(
                content: "",
                error: "Invalid URL format",
                lastUpdated: Date()
            )
        }
        
        // If using server, query the PageQueryServer
        if configuration.useServer {
            log("Using PageQueryServer at: \(configuration.serverURL)")
            
            // Validate server URL
            guard let serverURL = URL(string: configuration.serverURL) else {
                log("Error: Invalid server URL format")
                return WebContent(
                    content: "",
                    error: "Invalid server URL format",
                    lastUpdated: Date()
                )
            }
            
            // Create API endpoint URL
            let extractURL = serverURL.appendingPathComponent("extract")
            
            do {
                // Create JSON request
                var requestDict: [String: Any] = [
                    "url": url,
                    "selector": querySelector,
                    "timeout": 45, // Default timeout
                    "first_only": !configuration.fetchAllMatches
                ]
                
                // Add JavaScript rendering flag if needed
                if useJavaScript {
                    requestDict["render_js"] = true
                    
                    // Add wait options if enabled
                    if configuration.enableWaitOptions {
                        log("Adding wait options for JavaScript rendering")
                        
                        var waitForDict: [String: Any] = [:]
                        
                        // Add load state - must be one of these specific values
                        if !configuration.loadState.isEmpty {
                            let validLoadStates = ["domcontentloaded", "load", "networkidle"]
                            if validLoadStates.contains(configuration.loadState) {
                                waitForDict["load_state"] = configuration.loadState
                                log("Load state: \(configuration.loadState)")
                            } else {
                                log("Warning: Invalid load state '\(configuration.loadState)'. Using default.")
                            }
                        }
                        
                        // Add wait for selector (must be a valid CSS selector string)
                        if !configuration.waitForSelector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let selector = configuration.waitForSelector.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // Basic validation to ensure it's not a number
                            if Double(selector) != nil || Int(selector) != nil {
                                log("Warning: Invalid wait_for_selector (appears to be a number). Using default.")
                            } else {
                                waitForDict["wait_for_selector"] = selector
                                log("Wait for selector: \(selector)")
                            }
                        }
                        
                        // Add additional wait time (limited to reasonable range)
                        let waitTime = max(0, min(configuration.additionalWaitTime, 15))  // Allow up to 15 seconds
                        if waitTime > 0 {
                            waitForDict["wait_time"] = waitTime
                            log("Additional wait time: \(waitTime) seconds")
                        }
                        
                        // Only add wait_for if we have at least one option
                        if !waitForDict.isEmpty {
                            requestDict["wait_for"] = waitForDict
                            log("Adding wait_for options to request: \(waitForDict)")
                        } else {
                            log("No valid wait options provided, skipping wait_for parameter")
                        }
                    }
                }
                
                let requestData = try JSONSerialization.data(withJSONObject: requestDict)
                
                // Create request
                var request = URLRequest(url: extractURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Add API key if provided
                if !configuration.apiKey.isEmpty {
                    request.setValue(configuration.apiKey, forHTTPHeaderField: "Authorization")
                    log("Added API key to request")
                }
                
                request.httpBody = requestData
                
                // Create a URLSession configuration with a reasonable timeout
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 60
                config.timeoutIntervalForResource = 90
                
                // Create the URL session
                let session = URLSession(configuration: config)
                
                log("Sending request to PageQueryServer...")
                
                // Make the request
                let (data, response) = try await session.data(for: request)
                
                // Check the response
                guard let httpResponse = response as? HTTPURLResponse else {
                    log("Error: Not an HTTP response from server")
                    return WebContent(
                        content: "",
                        error: "Not an HTTP response from server",
                        lastUpdated: Date()
                    )
                }
                
                log("Received HTTP response with status code: \(httpResponse.statusCode)")
                
                // Check status code
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Try to parse error message from response
                    var errorMessage = "HTTP error: \(httpResponse.statusCode)"
                    
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorJson["error"] as? String {
                        errorMessage = error
                    }
                    
                    log("Server error: \(errorMessage)")
                    return WebContent(
                        content: "",
                        error: errorMessage,
                        lastUpdated: Date()
                    )
                }
                
                // Parse the JSON response
                guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let results = jsonResponse["results"] as? [[String: Any]] else {
                    log("Error: Invalid JSON response format")
                    return WebContent(
                        content: "",
                        error: "Invalid response format from server",
                        lastUpdated: Date()
                    )
                }
                
                log("Received \(results.count) results from server")
                
                if results.isEmpty {
                    log("No content found matching selector")
                    return WebContent(
                        content: "",
                        error: "No content found matching selector: \(querySelector)",
                        lastUpdated: Date()
                    )
                }
                
                // Process the results
                var contentParts: [String] = []
                
                for result in results {
                    if let text = result["text"] as? String, !text.isEmpty {
                        contentParts.append(text)
                    } else if let html = result["html"] as? String, !html.isEmpty {
                        contentParts.append(html)
                    }
                }
                
                // Join multiple results if needed
                let finalContent = contentParts.joined(separator: "\n")
                
                if finalContent.isEmpty {
                    log("Results contained no text content")
                    return WebContent(
                        content: "",
                        error: "Results contained no text content",
                        lastUpdated: Date()
                    )
                }
                
                // Return the content
                log("Content extracted successfully")
                return WebContent(
                    content: finalContent,
                    error: nil,
                    lastUpdated: Date()
                )
                
            } catch {
                log("Error querying server: \(error.localizedDescription)")
                return WebContent(
                    content: "",
                    error: "Error querying server: \(error.localizedDescription)",
                    lastUpdated: Date()
                )
            }
        }
        
        // Fall back to direct fetching if server isn't enabled
        if useJavaScript {
            log("⚠️ JavaScript rendering is not supported in the Swift-only version")
            log("For JavaScript-rendered content, you need to use the PageQueryServer or the Node.js version with Puppeteer")
            return WebContent(
                content: "",
                error: "JavaScript rendering is not supported in the Swift-only version. Please enable PageQueryServer or install Node.js for dynamic websites.",
                lastUpdated: Date()
            )
        }
        
        do {
            // Create a URLSession configuration with a reasonable timeout
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            
            // Create the URL session
            let session = URLSession(configuration: config)
            
            log("Fetching URL: \(url)")
            
            // Make the request
            let (data, response) = try await session.data(from: urlObj)
            
            // Check the response
            guard let httpResponse = response as? HTTPURLResponse else {
                log("Error: Not an HTTP response")
                return WebContent(
                    content: "",
                    error: "Not an HTTP response",
                    lastUpdated: Date()
                )
            }
            
            log("Received HTTP response with status code: \(httpResponse.statusCode)")
            
            // Check status code
            guard (200...299).contains(httpResponse.statusCode) else {
                log("HTTP error: \(httpResponse.statusCode)")
                return WebContent(
                    content: "",
                    error: "HTTP error: \(httpResponse.statusCode)",
                    lastUpdated: Date()
                )
            }
            
            // Get the response body as a string
            guard let htmlString = String(data: data, encoding: .utf8) else {
                log("Error: Could not decode response data as UTF-8")
                return WebContent(
                    content: "",
                    error: "Could not decode response data as UTF-8",
                    lastUpdated: Date()
                )
            }
            
            log("Received HTML content (length: \(htmlString.count) bytes)")
            
            // Parse the HTML using SwiftSoup
            do {
                // Parse the HTML
                let document = try SwiftSoup.parse(htmlString)
                log("Successfully parsed HTML document with SwiftSoup")
                
                // Try to select elements using the querySelector
                let elements = try document.select(querySelector)
                log("Selected \(elements.count) elements with selector: \(querySelector)")
                
                if elements.isEmpty() {
                    log("No elements found matching selector: \(querySelector)")
                    return WebContent(
                        content: "",
                        error: "No content found matching selector: \(querySelector)",
                        lastUpdated: Date()
                    )
                }
                
                // Get the first matching element
                let element = elements.first()!
                
                // Determine what content to extract based on element type
                var content = ""
                
                // Check if it's an image tag
                if element.tagName() == "img" {
                    content = try element.attr("src")
                    log("Extracted image source URL from img tag")
                } 
                // Check if it's a link
                else if element.tagName() == "a" {
                    let text = try element.text()
                    let href = try element.attr("href")
                    content = "\(text) (\(href))"
                    log("Extracted text and link from anchor tag")
                }
                // Check if it has child elements and we want the full HTML
                else if !element.children().isEmpty() && querySelector.contains(":html") {
                    content = try element.html()
                    log("Extracted HTML content from element")
                }
                // Default to text content
                else {
                    content = try element.text()
                    log("Extracted text content from element")
                }
                
                // Clean the content
                let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                log("Content extracted: \(trimmedContent.prefix(100))\(trimmedContent.count > 100 ? "..." : "")")
                
                // Return the content
                return WebContent(
                    content: trimmedContent,
                    error: nil,
                    lastUpdated: Date()
                )
                
            } catch let parsingError as SwiftSoup.Exception {
                log("SwiftSoup error: \(parsingError.localizedDescription)")
                return WebContent(
                    content: "",
                    error: "HTML parsing error: \(parsingError)",
                    lastUpdated: Date()
                )
            } catch {
                log("Unexpected parsing error: \(error.localizedDescription)")
                return WebContent(
                    content: "",
                    error: "Unexpected parsing error: \(error.localizedDescription)",
                    lastUpdated: Date()
                )
            }
            
        } catch {
            log("Error fetching content: \(error.localizedDescription)")
            return WebContent(
                content: "",
                error: "Error fetching content: \(error.localizedDescription)",
                lastUpdated: Date()
            )
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let webContent: WebContent
}

struct PageWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    // Format error message to be more concise and helpful
    var formattedError: String {
        guard let error = entry.webContent.error else { return "" }
        
        // For configuration errors
        if error.contains("Please enter") || 
           error.contains("must start with") ||
           error.contains("requires server mode") ||
           error.contains("Invalid") {
            return "Configuration error: \(error)"
        }
        
        // For timeout errors
        if error.contains("Timed out") {
            return "Timed out loading content"
        }
        
        // For connection errors
        if error.contains("Could not connect") || error.contains("connection") {
            return "Connection error: Unable to reach server"
        }
        
        // For authentication errors
        if error.contains("Authentication") || error.contains("API key") {
            return "Authentication error: \(error)"
        }
        
        // For selector errors
        if error.contains("No content found") || error.contains("selector") {
            return "Selector error: No content found"
        }
        
        // For server errors
        if error.contains("Server error") || (error.contains("HTTP error") && error.contains("5")) {
            return "Server error: The content server is experiencing issues"
        }
        
        // For JavaScript errors
        if error.contains("JavaScript") {
            return "JavaScript error: \(error)"
        }
        
        // For other errors, limit to reasonable length
        let maxLength = family == .systemSmall ? 50 : 100
        if error.count > maxLength {
            return String(error.prefix(maxLength)) + "..."
        }
        
        return error
    }
    
    // Get user-friendly guidance based on error
    var errorGuidance: String {
        guard let error = entry.webContent.error else { return "" }
        
        if error.contains("Please enter a website URL") {
            return "Add a URL in widget settings"
        }
        
        if error.contains("Please enter a CSS selector") {
            return "Add a CSS selector in settings"
        }
        
        if error.contains("must start with http://") {
            return "URL must include http:// or https://"
        }
        
        if error.contains("JavaScript rendering requires server mode") {
            return "Enable 'Use Server' for JS support"
        }
        
        if error.contains("'Fetch All Matches' requires server mode") {
            return "Enable 'Use Server' to fetch all matches"
        }
        
        if error.contains("No content found") {
            return "Try a different CSS selector"
        }
        
        if error.contains("Server URL") {
            return "Check server URL in settings"
        }
        
        if error.contains("Could not connect") || error.contains("connection") {
            return "Verify server is running"
        }
        
        if error.contains("Authentication") || error.contains("API key") {
            return "Check API key in settings"
        }
        
        return "Check widget settings"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and URL
            Text(entry.configuration.label)
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text(entry.configuration.websiteURL)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundColor(.gray)
            
            // Content from the website
            if let _ = entry.webContent.error {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: errorIcon)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(errorType)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    }
                    
                    Text(formattedError)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(family == .systemSmall ? 2 : 3)
                    
                    // Show guidance for errors
                    if !errorGuidance.isEmpty {
                        Text(errorGuidance)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .padding(.top, 2)
                    }
                }
            } else {
                // Display content based on whether we're showing multiple results
                if entry.configuration.useServer && entry.configuration.fetchAllMatches {
                    multipleResultsView
                } else {
                    Text(entry.webContent.content)
                        .font(family == .systemSmall ? .caption : .body)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .lineLimit(getLineLimit())
                }
            }
            
            Spacer()
            
            HStack {
                // Display when the content was last updated
                Text("Updated: \(timeFormatter.string(from: entry.webContent.lastUpdated))")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Server indicator
                if entry.configuration.useServer {
                    Text("Server")
                        .font(.caption2)
                        .padding(2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(3)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                
                // JavaScript indicator
                if entry.configuration.useJavaScript {
                    Text("JS")
                        .font(.caption2)
                        .padding(2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(3)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                
                // Wait options indicator
                if entry.configuration.enableWaitOptions && entry.configuration.useJavaScript {
                    Text("Wait")
                        .font(.caption2)
                        .padding(2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(3)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
        }
        .padding(10)
    }
    
    // Error icon based on error type
    var errorIcon: String {
        guard let error = entry.webContent.error else { return "exclamationmark.triangle" }
        
        if error.contains("Please enter") || error.contains("must start with") || error.contains("Invalid") {
            return "gear.badge.exclamationmark"
        }
        
        if error.contains("No content found") || error.contains("selector") {
            return "magnifyingglass"
        }
        
        if error.contains("JavaScript") {
            return "arrow.clockwise.icloud"
        }
        
        if error.contains("Could not connect") || error.contains("connection") || error.contains("Server") {
            return "wifi.exclamationmark"
        }
        
        if error.contains("Authentication") || error.contains("API key") {
            return "lock"
        }
        
        return "exclamationmark.triangle"
    }
    
    // Error type based on error message
    var errorType: String {
        guard let error = entry.webContent.error else { return "Error" }
        
        if error.contains("Please enter") || error.contains("must start with") || 
           error.contains("requires server mode") || error.contains("Invalid") {
            return "Setup Error"
        }
        
        if error.contains("No content found") || error.contains("selector") {
            return "Content Error"
        }
        
        if error.contains("JavaScript") {
            return "JS Error"
        }
        
        if error.contains("Could not connect") || error.contains("connection") {
            return "Connection Error"
        }
        
        if error.contains("Server") {
            return "Server Error"
        }
        
        if error.contains("Authentication") || error.contains("API key") {
            return "Auth Error"
        }
        
        return "Error"
    }
    
    // Helper view for displaying multiple results with separators
    var multipleResultsView: some View {
        let results = entry.webContent.content.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        return VStack(alignment: .leading, spacing: 0) {
            if results.isEmpty {
                Text("No results found")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                // For small widgets, just show the count and first item
                if family == .systemSmall {
                    Text("\(results.count) items found")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)
                    
                    if let first = results.first {
                        Text(first)
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .lineLimit(2)
                    }
                } else {
                    // For medium and large widgets, show a scrollable list
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(results.indices, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(results[index])
                                        .font(family == .systemMedium ? .caption : .body)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .lineLimit(family == .systemMedium ? 2 : 4)
                                    
                                    if index < results.count - 1 {
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                            .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(maxHeight: getMaxHeight())
                }
            }
        }
    }
    
    // Helper to determine max height for scrollable content
    func getMaxHeight() -> CGFloat {
        switch family {
        case .systemSmall:
            return 80
        case .systemMedium:
            return 120
        case .systemLarge:
            return 280
        default:
            return 120
        }
    }
    
    // Helper to determine line limit based on widget size
    func getLineLimit() -> Int {
        switch family {
        case .systemSmall:
            return 3
        case .systemMedium:
            return 5
        case .systemLarge:
            return 15
        default:
            return 5
        }
    }
}

struct PageWidget: Widget {
    let kind: String = "PageWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            PageWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    // Use the standard widget background
                    Color.clear
                }
        }
        .configurationDisplayName("Web Content Widget")
        .description("Display content from any website using CSS selectors. Supports JavaScript rendering for dynamic websites.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    PageWidget()
} timeline: {
    SimpleEntry(
        date: Date(),
        configuration: ConfigurationAppIntent(),
        webContent: WebContent(
            content: "This is sample content for the small widget",
            error: nil,
            lastUpdated: Date()
        )
    )
}

#Preview(as: .systemMedium) {
    PageWidget()
} timeline: {
    SimpleEntry(
        date: Date(),
        configuration: ConfigurationAppIntent(),
        webContent: WebContent(
            content: "This is sample content for the medium widget. It shows more text than the small widget.",
            error: nil,
            lastUpdated: Date()
        )
    )
}

#Preview(as: .systemLarge) {
    PageWidget()
} timeline: {
    SimpleEntry(
        date: Date(),
        configuration: ConfigurationAppIntent(),
        webContent: WebContent(
            content: "This is sample content for the large widget. It can display much more text and information than the smaller widgets. This is ideal for content that needs more space to be properly displayed, such as detailed information or longer text snippets from websites.",
            error: nil,
            lastUpdated: Date()
        )
    )
}

// Preview with configuration error
#Preview("Configuration Error", as: .systemSmall) {
    PageWidget()
} timeline: {
    let errorConfig = ConfigurationAppIntent()
    SimpleEntry(
        date: Date(),
        configuration: errorConfig,
        webContent: WebContent(
            content: "",
            error: "JavaScript rendering requires server mode to be enabled. Please enable 'Use Server' or disable 'Use JavaScript'.",
            lastUpdated: Date()
        )
    )
}

// Preview with server error
#Preview("Server Error", as: .systemMedium) {
    PageWidget()
} timeline: {
    let serverConfig: ConfigurationAppIntent = {
        let config = ConfigurationAppIntent()
        config.useServer = true
        config.serverURL = "http://127.0.0.1:5000"
        return config
    }()
    
    SimpleEntry(
        date: Date(),
        configuration: serverConfig,
        webContent: WebContent(
            content: "",
            error: "Could not connect to server: Connection refused",
            lastUpdated: Date()
        )
    )
}

// Preview with selector error
#Preview("Selector Error", as: .systemMedium) {
    PageWidget()
} timeline: {
    let selectorConfig = ConfigurationAppIntent()
    
    SimpleEntry(
        date: Date(),
        configuration: selectorConfig,
        webContent: WebContent(
            content: "",
            error: "No content found matching selector: .nonexistent-element",
            lastUpdated: Date()
        )
    )
}

// Preview with multiple results
#Preview("Multiple Results", as: .systemLarge) {
    PageWidget()
} timeline: {
    let multiConfig: ConfigurationAppIntent = {
        let config = ConfigurationAppIntent()
        config.useServer = true
        config.fetchAllMatches = true
        return config
    }()
    
    SimpleEntry(
        date: Date(),
        configuration: multiConfig,
        webContent: WebContent(
            content: "First Result\nSecond Result\nThird Result\nFourth Result\nFifth Result",
            error: nil,
            lastUpdated: Date()
        )
    )
}
