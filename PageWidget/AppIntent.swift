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
}
