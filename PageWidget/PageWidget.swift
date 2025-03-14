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
        
        // Extract content from the website
        let webContent = await fetchWebContent(
            configuration: configuration,
            url: configuration.websiteURL,
            querySelector: configuration.querySelector,
            useJavaScript: configuration.useJavaScript
        )
        
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
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    // Format error message to be more concise
    var formattedError: String {
        guard let error = entry.webContent.error else { return "" }
        
        // For timeout errors, show a shorter message
        if error.contains("Timed out") {
            return "Timed out loading JavaScript content"
        }
        
        // For no content errors, show a shorter message
        if error.contains("No content found") {
            return "No content found with selector"
        }
        
        // For other errors, limit to reasonable length
        let maxLength = family == .systemSmall ? 50 : 100
        if error.count > maxLength {
            return String(error.prefix(maxLength)) + "..."
        }
        
        return error
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and URL
            Text(entry.configuration.label)
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Text(entry.configuration.websiteURL)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundColor(.secondary)
            
            // Content from the website
            if let _ = entry.webContent.error {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    }
                    
                    Text(formattedError)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(family == .systemSmall ? 2 : 3)
                }
            } else {
                // Display content based on whether we're showing multiple results
                if entry.configuration.useServer && entry.configuration.fetchAllMatches {
                    displayMultipleResults
                } else {
                    Text(entry.webContent.content)
                        .font(family == .systemSmall ? .caption : .body)
                        .lineLimit(getLineLimit())
                }
            }
            
            Spacer()
            
            HStack {
                // Display when the content was last updated
                Text("Updated: \(timeFormatter.string(from: entry.webContent.lastUpdated))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Server indicator
                if entry.configuration.useServer {
                    Text("Server")
                        .font(.caption2)
                        .padding(2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(3)
                }
                
                // JavaScript indicator
                if entry.configuration.useJavaScript {
                    Text("JS")
                        .font(.caption2)
                        .padding(2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(3)
                }
            }
        }
        .padding(10)
    }
    
    // Helper view for displaying multiple results with separators
    var displayMultipleResults: some View {
        let results = entry.webContent.content.components(separatedBy: "\n")
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<results.count, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(results[index])
                            .font(family == .systemSmall ? .caption : .body)
                        
                        if index < results.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(maxHeight: getMaxHeight())
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
                .containerBackground(.fill.tertiary, for: .widget)
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
