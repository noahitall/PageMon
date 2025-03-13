//
//  PageWidgetPreview.swift
//  PageWidget
//
//  Created for PageMon project
//

import SwiftUI
import WidgetKit

// This file contains preview configurations for testing the widget

struct PageWidgetPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("PageWidget Preview")
                .font(.title)
                .padding()
            
            Text("Small Widget")
                .font(.headline)
            PreviewContainer(size: .small)
            
            Text("Medium Widget")
                .font(.headline)
            PreviewContainer(size: .medium)
            
            Text("Large Widget")
                .font(.headline)
            PreviewContainer(size: .large)
        }
        .padding()
    }
    
    struct PreviewContainer: View {
        enum WidgetSize {
            case small, medium, large
        }
        
        let size: WidgetSize
        
        var body: some View {
            let priceConfig = createConfig(
                url: "https://www.amazon.com/Apple-MacBook-16-inch-10%E2%80%91core-16%E2%80%91core/dp/B09JQSLL92/",
                label: "MacBook Pro Price",
                selector: "#corePriceDisplay_desktop_feature_div"
            )
            
            let newsConfig = createConfig(
                url: "https://news.ycombinator.com/",
                label: "Top HN Story",
                selector: ".title a"
            )
            
            let weatherConfig = createConfig(
                url: "https://weather.com",
                label: "Current Weather",
                selector: ".CurrentConditions--tempValue--MHmYY"
            )
            
            // Select different examples based on size
            Group {
                switch size {
                case .small:
                    PageWidgetEntryView(entry: previewEntry(config: priceConfig))
                case .medium:
                    PageWidgetEntryView(entry: previewEntry(config: newsConfig))
                case .large:
                    PageWidgetEntryView(entry: previewEntry(config: weatherConfig))
                }
            }
            .frame(width: widgetSize.width, height: widgetSize.height)
            .background(Color.gray.opacity(0.2))  // Use SwiftUI native color
            .cornerRadius(20)
        }
        
        private var widgetSize: CGSize {
            switch size {
            case .small:
                return CGSize(width: 170, height: 170)
            case .medium:
                return CGSize(width: 360, height: 170)
            case .large:
                return CGSize(width: 360, height: 380)
            }
        }
        
        private func createConfig(url: String, label: String, selector: String) -> ConfigurationAppIntent {
            let config = ConfigurationAppIntent()
            config.websiteURL = url
            config.label = label
            config.querySelector = selector
            return config
        }
        
        private func previewEntry(config: ConfigurationAppIntent) -> SimpleEntry {
            let sampleContent: String
            
            switch config.querySelector {
            case "#corePriceDisplay_desktop_feature_div":
                sampleContent = "$2,299.00"
            case ".title a":
                sampleContent = "Apple announces new M3 MacBook Pro models"
            case ".CurrentConditions--tempValue--MHmYY":
                sampleContent = "72°"
            default:
                sampleContent = "Sample content for \(config.label)"
            }
            
            return SimpleEntry(
                date: Date(),
                configuration: config,
                webContent: WebContent(
                    content: sampleContent,
                    error: nil,
                    lastUpdated: Date()
                )
            )
        }
    }
}

#Preview {
    PageWidgetPreview()
} 