//
//  PageWidget.swift
//  PageWidget
//
//  Created by Noah Zitsman on 3/13/25.
//

import WidgetKit
import SwiftUI
import WebKit
// Import SwiftSoup library - Note: we may need to set up module import properly in the project
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
            url: configuration.websiteURL,
            querySelector: configuration.querySelector
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
    
    private func fetchWebContent(url: String, querySelector: String) async -> WebContent {
        guard let url = URL(string: url) else {
            return WebContent(
                content: "",
                error: "Invalid URL format",
                lastUpdated: Date()
            )
        }
        
        do {
            // Fetch the website content
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check for valid response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return WebContent(
                    content: "",
                    error: "Website returned error: \(response)",
                    lastUpdated: Date()
                )
            }
            
            // Convert to string
            guard let htmlString = String(data: data, encoding: .utf8) else {
                return WebContent(
                    content: "",
                    error: "Unable to parse website content",
                    lastUpdated: Date()
                )
            }
            
            // Use SwiftSoup to extract content
            let extractedContent = try extractContentWithSwiftSoup(from: htmlString, using: querySelector)
            
            return WebContent(
                content: extractedContent,
                error: nil,
                lastUpdated: Date()
            )
        } catch let error as SwiftSoup.Exception {
            // SwiftSoup specific errors - using String representation instead of property access
            return WebContent(
                content: "",
                error: "HTML parsing error: \(error)",
                lastUpdated: Date()
            )
        } catch {
            // Other errors
            return WebContent(
                content: "",
                error: "Error fetching website: \(error.localizedDescription)",
                lastUpdated: Date()
            )
        }
    }
    
    // New method that uses SwiftSoup for proper HTML parsing with CSS selectors
    private func extractContentWithSwiftSoup(from html: String, using querySelector: String) throws -> String {
        let doc = try SwiftSoup.parse(html)
        
        // Select elements with the provided CSS selector
        let elements = try doc.select(querySelector)
        
        if elements.isEmpty() {
            // No elements found with this selector
            let bodyText = try doc.body()?.text() ?? ""
            let previewText = String(bodyText.prefix(100))
            return "No content found matching '\(querySelector)'. Page preview: \(previewText)..."
        }
        
        // Get the first matching element
        let element = elements.first()!
        
        // Different content handling based on selector type
        if querySelector.lowercased().contains("img") || element.tagName() == "img" {
            // For images, get the src attribute
            return try element.attr("src")
        } else if element.tagName() == "a" {
            // For links, show both text and href
            let text = try element.text()
            let href = try element.attr("href")
            return "\(text) (\(href))"
        } else if element.children().size() > 0 && !querySelector.contains(":text") {
            // For elements with children, get the HTML content
            return try element.html()
        } else {
            // For text nodes or simple elements, get just the text
            return try element.text()
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
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(entry.configuration.label)
                .font(titleFont)
                .fontWeight(.bold)
                .lineLimit(1)
                .padding(.bottom, 2)
            
            if let error = entry.webContent.error {
                // Error message
                VStack(alignment: .leading) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Error:")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Content
                Text(entry.webContent.content)
                    .font(contentFont)
                    .lineLimit(contentLineLimit)
            }
            
            Spacer()
            
            // Footer with last updated time
            HStack {
                Spacer()
                Text("Updated: \(entry.webContent.lastUpdated, formatter: timeFormatter)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    // Responsive font sizes based on widget size
    private var titleFont: Font {
        switch widgetFamily {
        case .systemSmall:
            return .caption
        case .systemMedium:
            return .callout
        case .systemLarge:
            return .title3
        default:
            return .body
        }
    }
    
    private var contentFont: Font {
        switch widgetFamily {
        case .systemSmall:
            return .caption2
        case .systemMedium:
            return .caption
        case .systemLarge:
            return .callout
        default:
            return .caption
        }
    }
    
    private var contentLineLimit: Int {
        switch widgetFamily {
        case .systemSmall:
            return 3
        case .systemMedium:
            return 6
        case .systemLarge:
            return 12
        default:
            return 4
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

struct PageWidget: Widget {
    let kind: String = "PageWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            PageWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Page Monitor")
        .description("Monitor specific content on websites.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Use the correct syntax for widget previews
struct PageWidget_Previews: PreviewProvider {
    static var previews: some View {
        // Sample entries for previews
        let smallEntry = SimpleEntry(
            date: Date(),
            configuration: sampleConfig(label: "Small Widget"),
            webContent: WebContent(
                content: "This is sample content for a small widget.",
                error: nil, 
                lastUpdated: Date()
            )
        )
        
        let mediumEntry = SimpleEntry(
            date: Date(),
            configuration: sampleConfig(label: "Medium Widget"),
            webContent: WebContent(
                content: "This is sample content for a medium widget. It can display more text and information than the small widget.",
                error: nil, 
                lastUpdated: Date()
            )
        )
        
        let largeEntry = SimpleEntry(
            date: Date(),
            configuration: sampleConfig(label: "Large Widget"),
            webContent: WebContent(
                content: "This is sample content for a large widget. It can display much more text and information than the smaller widgets. This is ideal for content that needs more space to be properly displayed, such as detailed information or longer text snippets from websites.",
                error: nil, 
                lastUpdated: Date()
            )
        )
        
        // Error state entry
        let errorEntry = SimpleEntry(
            date: Date(),
            configuration: sampleConfig(label: "Error Example"),
            webContent: WebContent(
                content: "",
                error: "Could not connect to the website. Check your internet connection and try again.", 
                lastUpdated: Date()
            )
        )
        
        Group {
            PageWidgetEntryView(entry: smallEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget")
            
            PageWidgetEntryView(entry: mediumEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Widget")
                
            PageWidgetEntryView(entry: largeEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large Widget")
                
            PageWidgetEntryView(entry: errorEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Error State")
        }
    }
    
    // Helper to create sample configurations
    static func sampleConfig(label: String) -> ConfigurationAppIntent {
        let config = ConfigurationAppIntent()
        config.websiteURL = "https://example.com"
        config.label = label
        config.querySelector = "body"
        return config
    }
}
