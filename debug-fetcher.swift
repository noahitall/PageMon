#!/usr/bin/env swift

import Foundation

// MARK: - Constants
let VERSION = "1.0"
let LOG_DIR = FileManager.default.temporaryDirectory.appendingPathComponent("PageMonLogs")
let LOG_FILE = LOG_DIR.appendingPathComponent("debug-fetcher-\(Date().timeIntervalSince1970).log")

// MARK: - Models
struct NodeResponse: Codable {
    var content: String
    var error: String?
    var date: String
}

struct WebContent {
    var content: String
    var error: String?
    var lastUpdated: Date
}

// MARK: - Setup
try FileManager.default.createDirectory(at: LOG_DIR, withIntermediateDirectories: true)

// MARK: - Logging
func log(_ message: String) {
    print(message)
    if let data = (message + "\n").data(using: .utf8) {
        if let fileHandle = try? FileHandle(forWritingTo: LOG_FILE) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            try? fileHandle.close()
        } else {
            try? data.write(to: LOG_FILE, options: .atomic)
        }
    }
}

// MARK: - Command Line Arguments
func printUsage() {
    print("PageMon Content Fetcher Debugger v\(VERSION)")
    print("Usage: ./debug-fetcher.swift [options]")
    print("")
    print("Options:")
    print("  --url=URL              URL to fetch content from (required)")
    print("  --selector=SELECTOR    CSS selector to extract content (required)")
    print("  --js, --javascript     Enable JavaScript rendering for dynamic sites")
    print("  --verbose              Show detailed logs")
    print("  --help                 Show this help message")
    print("")
    print("Example:")
    print("  ./debug-fetcher.swift --url=https://example.com --selector=h1")
}

var url: String?
var selector: String?
var useJavaScript = false
var verbose = false

for arg in CommandLine.arguments[1...] {
    if arg.starts(with: "--url=") {
        url = String(arg.dropFirst(6))
    } else if arg.starts(with: "--selector=") {
        selector = String(arg.dropFirst(11))
    } else if arg == "--js" || arg == "--javascript" {
        useJavaScript = true
    } else if arg == "--verbose" {
        verbose = true
    } else if arg == "--help" {
        printUsage()
        exit(0)
    }
}

guard let url = url, !url.isEmpty else {
    print("Error: URL is required")
    printUsage()
    exit(1)
}

guard let selector = selector, !selector.isEmpty else {
    print("Error: Selector is required")
    printUsage()
    exit(1)
}

// MARK: - Content Fetching
log("PageMon Content Fetcher Debugger v\(VERSION)")
log("---------------------------------------")
log("Starting content fetch at: \(Date())")
log("URL: \(url)")
log("Selector: \(selector)")
log("JavaScript Enabled: \(useJavaScript)")
log("Log file: \(LOG_FILE.path)")
log("")

// Find content fetcher scripts
let possibleScriptDirs = [
    // First try absolute paths that are most likely to work
    "/Users/noah/Applications/PageMon/PageContentFetcher",
    NSHomeDirectory() + "/Applications/PageMon/PageContentFetcher", // User Applications
    "/Applications/PageMon/PageContentFetcher", // System Applications
    
    // Then try various relative paths
    "/Users/noah/ai/PageMon/PageContentFetcher", // Development path
    "/usr/local/lib/PageMon/PageContentFetcher", // Unix standard location
    FileManager.default.currentDirectoryPath + "/PageContentFetcher" // Current directory
]

log("Searching for content fetcher scripts...")
var scriptDir: String? = nil
var directFetchPath: String? = nil

for dir in possibleScriptDirs {
    let directPath = "\(dir)/direct-fetch.js"
    
    if verbose {
        log("Checking for scripts in: \(dir)")
    }
    
    if FileManager.default.fileExists(atPath: directPath) {
        scriptDir = dir
        directFetchPath = directPath
        log("Found direct-fetch.js at: \(dir)")
        break
    }
}

// If direct-fetch.js was not found, try to find index.js as fallback
if directFetchPath == nil {
    log("direct-fetch.js not found, looking for index.js...")
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

// If no script directory was found, exit with error
guard let scriptDir = scriptDir, let scriptPath = directFetchPath else {
    log("❌ Error: Content fetcher scripts not found in any of the expected locations")
    log("Checked the following locations:")
    for dir in possibleScriptDirs {
        log("- \(dir)")
    }
    log("")
    log("Please install the PageMon content fetcher using the installer.")
    exit(1)
}

// Escape URL and selector for command line
let escapedURL = url.replacingOccurrences(of: "\"", with: "\\\"")
let escapedSelector = selector.replacingOccurrences(of: "\"", with: "\\\"")

// Build the command
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
log("")

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

do {
    // Run the process
    try process.run()
    
    // Read stderr
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
    if let stderrOutput = String(data: stderrData, encoding: .utf8), !stderrOutput.isEmpty {
        log("STDERR Output:")
        log(stderrOutput)
        log("")
    }
    
    // Read stdout
    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: stdoutData, encoding: .utf8) ?? ""
    
    log("Raw output:")
    log(output)
    log("")
    
    // Try to parse JSON
    if let jsonData = output.data(using: .utf8) {
        do {
            let response = try JSONDecoder().decode(NodeResponse.self, from: jsonData)
            
            log("✅ Successfully parsed response:")
            log("Content: \(response.content)")
            if let error = response.error, !error.isEmpty {
                log("Error: \(error)")
            }
            log("Date: \(response.date)")
            
            log("")
            log("Content preview:")
            log("--------------")
            if response.content.count > 500 {
                log(String(response.content.prefix(500)) + "... (truncated)")
            } else {
                log(response.content)
            }
            
        } catch {
            log("❌ JSON parsing error: \(error)")
            
            // Try more lenient parsing
            if let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                log("JSON structure found with keys: \(json.keys.joined(separator: ", "))")
                
                if let content = json["content"] as? String {
                    log("Content: \(content)")
                }
                
                if let error = json["error"] as? String {
                    log("Error: \(error)")
                }
            }
        }
    } else {
        log("❌ Output is not valid JSON")
    }
    
    process.waitUntilExit()
    
    log("")
    log("Process exited with code: \(process.terminationStatus)")
    if process.terminationStatus == 0 {
        log("✅ Content fetching completed successfully")
    } else {
        log("❌ Content fetching failed")
    }
    
} catch {
    log("❌ Failed to run process: \(error)")
    exit(1)
}

log("")
log("Debug log saved to: \(LOG_FILE.path)") 