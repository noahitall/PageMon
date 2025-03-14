//
//  ContentView.swift
//  PageMon
//
//  Created by Noah Zitsman on 3/13/25.
//

import SwiftUI
import WebKit
import Foundation
import AppIntents

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentFetcherDebugView()
                .tabItem {
                    Label("Debug Widget", systemImage: "ladybug")
                }
                .tag(0)
            
            LogViewerView()
                .tabItem {
                    Label("Logs", systemImage: "doc.text")
                }
                .tag(1)
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(2)
        }
        .padding()
    }
}

// MARK: - Content Fetcher Debug View
struct ContentFetcherDebugView: View {
    @State private var url = "https://example.com"
    @State private var selector = "h1"
    @State private var useJavaScript = false
    @State private var isLoading = false
    @State private var content = ""
    @State private var errorMessage = ""
    @State private var lastUpdated: Date?
    @State private var showWebPreview = false
    @State private var widgetSize: WidgetSize = .medium
    
    enum WidgetSize: String, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        
        var id: String { self.rawValue }
        
        var family: WidgetFamily {
            switch self {
            case .small: return .systemSmall
            case .medium: return .systemMedium
            case .large: return .systemLarge
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PageMon Debug Tool")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Test Content Fetching")
                        .font(.headline)
                    
                    TextField("URL", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                    
                    TextField("CSS Selector", text: $selector)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                    
                    Toggle("Use JavaScript (for dynamic sites)", isOn: $useJavaScript)
                        .padding(.vertical, 5)
                    
                    HStack {
                        Picker("Widget Size", selection: $widgetSize) {
                            ForEach(WidgetSize.allCases) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.trailing)
                        
                        Button(action: {
                            showWebPreview.toggle()
                        }) {
                            Label(showWebPreview ? "Hide Preview" : "Show Preview", systemImage: showWebPreview ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack {
                        Button(action: fetchContent) {
                            Text("Fetch Content")
                                .padding(.horizontal, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading)
                        
                        Button(action: diagnoseEnvironment) {
                            Text("Run Diagnostics")
                                .padding(.horizontal, 10)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isLoading)
                        
                        if isLoading {
                            ProgressView()
                                .padding(.leading, 10)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)
            
            Divider()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Widget Preview")
                        .font(.headline)
                    Spacer()
                    Text(lastUpdated != nil ? "Updated: \(formatDate(lastUpdated!))" : "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                if errorMessage.isEmpty {
                    WidgetPreviewView(
                        content: content,
                        url: url,
                        error: nil,
                        useJavaScript: useJavaScript,
                        familyType: widgetSize.family
                    )
                    .frame(maxWidth: .infinity, maxHeight: familyHeight(widgetSize.family))
                    .padding()
                } else {
                    WidgetPreviewView(
                        content: "",
                        url: url,
                        error: errorMessage,
                        useJavaScript: useJavaScript,
                        familyType: widgetSize.family
                    )
                    .frame(maxWidth: .infinity, maxHeight: familyHeight(widgetSize.family))
                    .padding()
                }
            }
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(10)
            
            if showWebPreview {
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Web Page Preview")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    WebView(url: URL(string: url) ?? URL(string: "https://example.com")!)
                        .frame(height: 300)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
    }
    
    private func familyHeight(_ family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall: return 170
        case .systemMedium: return 170
        case .systemLarge: return 380
        default: return 170
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func fetchContent() {
        guard URL(string: url) != nil else {
            errorMessage = "Invalid URL format"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let result = try await runContentFetcher(url: url, selector: selector, useJavaScript: useJavaScript)
                
                DispatchQueue.main.async {
                    self.content = result.content
                    self.errorMessage = result.error ?? ""
                    self.lastUpdated = result.lastUpdated
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func diagnoseEnvironment() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await runDiagnostics()
                
                DispatchQueue.main.async {
                    self.errorMessage = "Diagnostics completed. Check logs tab for results."
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error running diagnostics: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func runDiagnostics() async throws {
        let possibleDiagnosticScripts = [
            "/Applications/PageMon/PageContentFetcher/diagnose-widget.sh",
            "\(NSHomeDirectory())/Applications/PageMon/PageContentFetcher/diagnose-widget.sh",
            "/usr/local/lib/PageMon/PageContentFetcher/diagnose-widget.sh"
        ]
        
        // Find the first existing script
        var scriptPath: String? = nil
        for path in possibleDiagnosticScripts {
            if FileManager.default.fileExists(atPath: path) {
                scriptPath = path
                break
            }
        }
        
        guard let scriptPath = scriptPath else {
            throw NSError(domain: "com.pagemon", code: 1, 
                          userInfo: [NSLocalizedDescriptionKey: "Diagnostic script not found"])
        }
        
        // Run the diagnostic script
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptPath]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw NSError(domain: "com.pagemon", code: Int(process.terminationStatus), 
                          userInfo: [NSLocalizedDescriptionKey: "Diagnostic script failed with code \(process.terminationStatus)"])
        }
    }
    
    // This mimics the widget's content fetcher logic for consistent testing
    private func runContentFetcher(url: String, selector: String, useJavaScript: Bool) async throws -> WebContent {
        // Set up logging
        let logsDir = FileManager.default.temporaryDirectory.appendingPathComponent("PageMonLogs")
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        let logFile = logsDir.appendingPathComponent("app-debug-\(Date().timeIntervalSince1970).log")
        
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
        log("Selector: \(selector)")
        log("JavaScript Enabled: \(useJavaScript)")
        
        // Try to find the content fetcher scripts in multiple locations
        let possibleScriptDirs = [
            // First try absolute paths that are most likely to work
            "/Users/noah/Applications/PageMon/PageContentFetcher",
            "\(NSHomeDirectory())/Applications/PageMon/PageContentFetcher", // User Applications
            "/Applications/PageMon/PageContentFetcher", // System Applications
            
            // Then try various relative paths
            "/Users/noah/ai/PageMon/PageContentFetcher", // Development path
            "/usr/local/lib/PageMon/PageContentFetcher", // Unix standard location
            Bundle.main.bundlePath + "/Contents/Resources/PageContentFetcher" // Within app bundle
        ]
        
        log("Searching for content fetcher scripts in multiple locations")
        
        // Find the first existing script directory
        var scriptDir: String? = nil
        var directFetchPath: String? = nil
        
        for dir in possibleScriptDirs {
            let directPath = "\(dir)/direct-fetch.js"
            
            log("Checking for scripts in: \(dir)")
            
            if FileManager.default.fileExists(atPath: directPath) {
                scriptDir = dir
                directFetchPath = directPath
                log("Found direct-fetch.js at: \(dir)")
                break
            }
        }
        
        // If direct-fetch.js was not found, try to find index.js as fallback
        if directFetchPath == nil {
            for dir in possibleScriptDirs {
                let indexPath = "\(dir)/index.js"
                
                if FileManager.default.fileExists(atPath: indexPath) {
                    scriptDir = dir
                    directFetchPath = indexPath
                    log("Found index.js at: \(dir) (fallback)")
                    break
                }
            }
        }
        
        // If no script directory was found, return error
        guard let scriptDir = scriptDir, let scriptPath = directFetchPath else {
            let errorMsg = "Content fetcher scripts not found in any of the expected locations"
            log("⚠️ \(errorMsg)")
            
            // List all checked locations
            log("Checked the following locations:")
            for dir in possibleScriptDirs {
                log("- \(dir)")
            }
            
            throw NSError(domain: "com.pagemon", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "\(errorMsg). Please install the PageMon content fetcher."
            ])
        }
        
        log("Using script directory: \(scriptDir)")
        log("Fetcher script: \(scriptPath)")
        
        // Escape the URL and selector for command line
        let escapedURL = url.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedSelector = selector.replacingOccurrences(of: "\"", with: "\\\"")
        
        // Build the command with explicit paths to ensure it works
        // Use direct execution of Node.js with full path to script
        let nodePath = "/usr/local/bin/node"
        var command = ""
        
        if FileManager.default.fileExists(atPath: nodePath) {
            // If we can find Node directly, use it with explicit path
            command = "\(nodePath) \"\(scriptPath)\" --url=\"\(escapedURL)\" --selector=\"\(escapedSelector)\" --debug"
        } else {
            // Fallback to hoping node is in PATH
            command = "node \"\(scriptPath)\" --url=\"\(escapedURL)\" --selector=\"\(escapedSelector)\" --debug"
        }
        
        if useJavaScript {
            command += " --useJavaScript"
        }
        
        log("Executing command: \(command)")
        
        // Create a process to run the command
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        
        // Using /bin/bash for better PATH resolution
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        // Set environment variables to ensure proper execution
        var environment = ProcessInfo.processInfo.environment
        let defaultPath = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        environment["PATH"] = "\(environment["PATH"] ?? ""):\(defaultPath)"
        process.environment = environment
        
        // Run the process
        log("Starting process with environment PATH: \(environment["PATH"] ?? "not set")")
        try process.run()
        
        // Get the output using async/await pattern
        let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            // Create a flag to track if we've already resumed
            var hasResumed = false
            
            // Create a task for reading stderr in the background
            DispatchQueue.global().async {
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                if let stderrOutput = String(data: stderrData, encoding: .utf8), !stderrOutput.isEmpty {
                    log("STDERR Output:")
                    log(stderrOutput)
                }
            }
            
            // Create a task for reading the data
            DispatchQueue.global().async {
                let fileHandle = stdoutPipe.fileHandleForReading
                
                do {
                    // This can throw if the file handle is closed
                    // We need to explicitly handle errors with try
                    #if os(macOS)
                    // In newer macOS versions, this can throw
                    let data = try fileHandle.readToEnd() ?? Data()
                    #else
                    // Fallback to non-throwing API on older systems
                    let data = fileHandle.readDataToEndOfFile()
                    #endif
                    
                    log("Received \(data.count) bytes of data")
                    
                    // Only resume if we haven't already
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: data)
                    }
                } catch {
                    log("Error reading data: \(error)")
                    
                    // Only resume if we haven't already
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            // Set a timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + 60) {
                // Terminate the process if it's still running
                if process.isRunning {
                    process.terminate()
                    log("Process terminated due to timeout")
                }
                
                // Only resume if we haven't already
                if !hasResumed {
                    hasResumed = true
                    log("Process timed out after 60 seconds")
                    continuation.resume(throwing: NSError(domain: "com.pagemon", code: 1, 
                        userInfo: [NSLocalizedDescriptionKey: "Process timed out after 60 seconds"]))
                }
            }
        }
        
        // Parse the JSON response
        if let output = String(data: data, encoding: .utf8) {
            log("Raw output: \(output)")
            
            // Try to clean/sanitize the output if it might contain invalid JSON
            let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
            log("Trimmed output: \(trimmedOutput)")
            
            if trimmedOutput.isEmpty {
                log("Received empty output")
                return WebContent(
                    content: "",
                    error: "No content received from fetcher",
                    lastUpdated: Date()
                )
            }
            
            // Try to parse the JSON by finding valid JSON in the output
            // This is more robust against extra content that might be in the output
            var jsonString = trimmedOutput
            
            // If the output contains multiple lines, try each line for valid JSON
            let lines = trimmedOutput.components(separatedBy: .newlines)
            if lines.count > 1 {
                log("Multiple lines found in output, searching for valid JSON")
                
                for line in lines {
                    let trimLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimLine.isEmpty { continue }
                    
                    // Check if this line starts with { (likely JSON)
                    if trimLine.hasPrefix("{") {
                        log("Possible JSON line found: \(trimLine)")
                        jsonString = trimLine
                        break
                    }
                }
            }
            
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    // Try to validate JSON first
                    let _ = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    log("JSON is valid")
                    
                    // Now try to decode to our expected model
                    let decoder = JSONDecoder()
                    let dateFormatter = ISO8601DateFormatter()
                    
                    // Try to decode the JSON
                    let response = try decoder.decode(NodeResponse.self, from: jsonData)
                    
                    // Convert to WebContent
                    let date = dateFormatter.date(from: response.date) ?? Date()
                    log("Successfully parsed response")
                    return WebContent(
                        content: response.content,
                        error: response.error,
                        lastUpdated: date
                    )
                } catch {
                    // JSON is not in the expected format
                    log("JSON parsing error: \(error)")
                    
                    // Try to extract useful info from the JSON
                    if let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                        log("JSON structure: \(json.keys)")
                        
                        // Try to extract content and date directly if they exist
                        if let content = json["content"] as? String {
                            log("Found content key in JSON")
                            let errorMsg = json["error"] as? String
                            let dateStr = json["date"] as? String
                            let date = dateStr != nil ? ISO8601DateFormatter().date(from: dateStr!) ?? Date() : Date()
                            
                            return WebContent(
                                content: content,
                                error: errorMsg,
                                lastUpdated: date
                            )
                        }
                        
                        // Try to extract error message if present
                        if let errorMsg = json["error"] as? String {
                            return WebContent(
                                content: "",
                                error: "Server error: \(errorMsg)",
                                lastUpdated: Date()
                            )
                        }
                    }
                    
                    // Provide detailed error for debugging
                    let errorDetails = """
                    Failed to parse response: \(error.localizedDescription)
                    Check logs at: \(logFile.path)
                    Output: \(trimmedOutput.prefix(100))
                    """
                    
                    return WebContent(
                        content: "",
                        error: errorDetails,
                        lastUpdated: Date()
                    )
                }
            } else {
                log("Could not convert output to JSON data")
                return WebContent(
                    content: "",
                    error: "Invalid response format. Check logs at: \(logFile.path)",
                    lastUpdated: Date()
                )
            }
        }
        
        log("No valid output received")
        return WebContent(
            content: "",
            error: "No valid output from content fetcher. Check logs at: \(logFile.path)",
            lastUpdated: Date()
        )
    }
    
    // Model for parsing the Node script's response
    struct NodeResponse: Codable {
        var content: String
        var error: String?
        var date: String
    }
}

// MARK: - Widget Preview View
struct WidgetPreviewView: View {
    let content: String
    let url: String
    let error: String?
    let useJavaScript: Bool
    let familyType: WidgetFamily
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var formattedError: String {
        guard let error = error else { return "" }
        
        // For timeout errors, show a shorter message
        if error.contains("Timed out") {
            return "Timed out loading JavaScript content"
        }
        
        // For no content errors, show a shorter message
        if error.contains("No content found") {
            return "No content found with selector"
        }
        
        // For other errors, limit to reasonable length
        let maxLength = familyType == .systemSmall ? 50 : 100
        if error.count > maxLength {
            return String(error.prefix(maxLength)) + "..."
        }
        
        return error
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and URL
            Text("PageMon")
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Text(url)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundColor(.secondary)
            
            // Content from the website
            if let _ = error {
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
                        .lineLimit(familyType == .systemSmall ? 2 : 3)
                }
            } else {
                Text(content)
                    .font(familyType == .systemSmall ? .caption : .body)
                    .lineLimit(getLineLimit())
            }
            
            Spacer()
            
            HStack {
                // Display when the content was last updated
                Text("Updated: \(timeFormatter.string(from: Date()))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // JavaScript indicator
                if useJavaScript {
                    Text("JS")
                        .font(.caption2)
                        .padding(2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(3)
                }
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
    
    // Helper to determine line limit based on widget size
    func getLineLimit() -> Int {
        switch familyType {
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

// MARK: - Log Viewer View
struct LogViewerView: View {
    @State private var logs: [LogFile] = []
    @State private var selectedLog: LogFile? = nil
    @State private var logContent = ""
    @State private var searchText = ""
    @State private var isRefreshing = false
    
    struct LogFile: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let path: String
        let date: Date
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: LogFile, rhs: LogFile) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    var body: some View {
        VStack {
            Text("PageMon Logs")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom)
            
            HStack {
                TextField("Search logs", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: refreshLogs) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isRefreshing)
                
                if isRefreshing {
                    ProgressView()
                        .padding(.leading, 5)
                }
            }
            .padding(.bottom)
            
            if logs.isEmpty {
                ContentUnavailableView("No Logs Found", systemImage: "doc.text")
                    .padding()
            } else {
                HStack(spacing: 0) {
                    // Log file list
                    List(filteredLogs, selection: $selectedLog) { log in
                        VStack(alignment: .leading) {
                            Text(log.name)
                                .font(.headline)
                            Text(formatDate(log.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(width: 250)
                    
                    // Log content
                    VStack {
                        if let _ = selectedLog {
                            ScrollView {
                                VStack(alignment: .leading) {
                                    Text(logContent)
                                        .font(.system(.body, design: .monospaced))
                                        .padding()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(Color(NSColor.textBackgroundColor))
                            
                            HStack {
                                Button(action: copyLogContent) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                
                                if let selectedLog = selectedLog {
                                    Button(action: { openLogInFinder(selectedLog) }) {
                                        Label("Show in Finder", systemImage: "folder")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding()
                        } else {
                            ContentUnavailableView("Select a Log", systemImage: "doc.text")
                                .padding()
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            refreshLogs()
        }
        .onChange(of: selectedLog) { _, _ in
            loadSelectedLogContent()
        }
    }
    
    private var filteredLogs: [LogFile] {
        if searchText.isEmpty {
            return logs
        } else {
            return logs.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func refreshLogs() {
        isRefreshing = true
        
        DispatchQueue.global().async {
            let logsDir = FileManager.default.temporaryDirectory.appendingPathComponent("PageMonLogs")
            var logFiles: [LogFile] = []
            
            do {
                if !FileManager.default.fileExists(atPath: logsDir.path) {
                    try FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
                }
                
                let fileURLs = try FileManager.default.contentsOfDirectory(at: logsDir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
                
                for fileURL in fileURLs {
                    if fileURL.pathExtension == "log" {
                        let attributes = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                        let modDate = attributes.contentModificationDate ?? Date()
                        
                        logFiles.append(LogFile(
                            name: fileURL.lastPathComponent,
                            path: fileURL.path,
                            date: modDate
                        ))
                    }
                }
                
                // Sort by date, newest first
                logFiles.sort { $0.date > $1.date }
                
                DispatchQueue.main.async {
                    self.logs = logFiles
                    self.isRefreshing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isRefreshing = false
                }
            }
        }
    }
    
    private func loadSelectedLogContent() {
        guard let selectedLog = selectedLog else { 
            logContent = ""
            return
        }
        
        DispatchQueue.global().async {
            do {
                let content = try String(contentsOfFile: selectedLog.path, encoding: .utf8)
                
                DispatchQueue.main.async {
                    self.logContent = content
                }
            } catch {
                DispatchQueue.main.async {
                    self.logContent = "Error loading log content: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func copyLogContent() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(logContent, forType: .string)
        #endif
    }
    
    private func openLogInFinder(_ log: LogFile) {
        #if os(macOS)
        NSWorkspace.shared.selectFile(log.path, inFileViewerRootedAtPath: "")
        #endif
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.viewfinder")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("PageMon")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0")
                .font(.title3)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("PageMon is a macOS widget that allows you to monitor content from any website. It extracts text based on CSS selectors and displays it in your widgets.")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
                
                Text("Features:")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 5) {
                    Label("Monitor content from any website", systemImage: "globe")
                    Label("Use CSS selectors to pinpoint specific content", systemImage: "cursorarrow.rays")
                    Label("JavaScript rendering for dynamic websites", systemImage: "chevron.left.forwardslash.chevron.right")
                    Label("Automatic regular updates", systemImage: "arrow.clockwise")
                    Label("Multiple widget sizes", systemImage: "rectangle.3.group")
                }
                .padding(.leading)
            }
            .padding()
            
            Divider()
                .padding(.vertical)
            
            HStack(spacing: 20) {
                Button(action: openInstallDirectory) {
                    Label("Open Install Directory", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                
                Button(action: openLogsDirectory) {
                    Label("Open Logs Directory", systemImage: "doc.text")
                }
                .buttonStyle(.bordered)
                
                Button(action: runInstaller) {
                    Label("Run Installer", systemImage: "arrow.down.app")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private func openInstallDirectory() {
        let possibleDirs = [
            "/Applications/PageMon",
            "\(NSHomeDirectory())/Applications/PageMon"
        ]
        
        for dir in possibleDirs {
            if FileManager.default.fileExists(atPath: dir) {
                #if os(macOS)
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: dir)
                #endif
                return
            }
        }
        
        // If not found, open the Applications folder
        #if os(macOS)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: "/Applications")
        #endif
    }
    
    private func openLogsDirectory() {
        let logsDir = FileManager.default.temporaryDirectory.appendingPathComponent("PageMonLogs")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: logsDir.path) {
            try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        }
        
        #if os(macOS)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: logsDir.path)
        #endif
    }
    
    private func runInstaller() {
        let possibleInstallers = [
            "/Applications/PageMon/install.sh",
            "\(NSHomeDirectory())/Applications/PageMon/install.sh",
            "/Users/noah/ai/PageMon/PageContentFetcher/install.sh"
        ]
        
        for installer in possibleInstallers {
            if FileManager.default.fileExists(atPath: installer) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/bash")
                process.arguments = [installer]
                
                do {
                    try process.run()
                } catch {
                    print("Failed to run installer: \(error)")
                }
                return
            }
        }
        
        // If no installer found, show alert (in a real app, add an alert here)
        print("No installer found")
    }
}

// MARK: - WebKit View
struct WebView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        nsView.load(request)
    }
}

// MARK: - Models
struct WebContent {
    var content: String
    var error: String?
    var lastUpdated: Date
}

enum WidgetFamily {
    case systemSmall
    case systemMedium
    case systemLarge
}

// Preview provider
#Preview {
    ContentView()
}
