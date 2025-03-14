//
//  AppIntent.swift
//  PageWidget
//
//  Created by Noah Zitsman on 3/13/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Page Monitor Configuration" }
    static var description: IntentDescription { "Configure the website monitoring widget." }

    @Parameter(title: "Website URL", description: "The URL of the website to monitor", default: "https://example.com")
    var websiteURL: String
    
    @Parameter(title: "Label", description: "Label to display above the content", default: "Website Content")
    var label: String
    
    @Parameter(title: "Query Selector", description: "CSS selector to extract specific content (e.g., '.main-content', '#price')", default: "body")
    var querySelector: String
    
    @Parameter(title: "Use JavaScript", description: "Enable JavaScript rendering (needed for dynamic sites, uses more resources)", default: false)
    var useJavaScript: Bool
    
    @Parameter(title: "Use Server", description: "Use PageQueryServer instead of direct fetching", default: false)
    var useServer: Bool
    
    @Parameter(title: "Server URL", description: "URL of the PageQueryServer (e.g., http://127.0.0.1:5000)", default: "http://127.0.0.1:5000")
    var serverURL: String
    
    @Parameter(title: "API Key", description: "Optional API key for server authentication", default: "")
    var apiKey: String
    
    @Parameter(title: "Fetch All Matches", description: "Fetch all matching elements instead of just the first one", default: false)
    var fetchAllMatches: Bool
    
    // JavaScript wait options
    @Parameter(title: "Enable Wait Options", description: "Configure wait options for JavaScript rendering", default: false)
    var enableWaitOptions: Bool
    
    @Parameter(title: "Load State", description: "Page load state to wait for (load, domcontentloaded, networkidle)", default: "load")
    var loadState: String
    
    @Parameter(title: "Wait for Selector", description: "Wait for a specific element to appear before extracting content", default: "")
    var waitForSelector: String
    
    @Parameter(title: "Additional Wait Time", description: "Extra time to wait in seconds after page load (0-10)", default: 0)
    var additionalWaitTime: Int
}
