#!/usr/bin/env swift

import Foundation

// Constants
let VERSION = "1.1.0"
let LOG_DIR = FileManager.default.temporaryDirectory.appendingPathComponent("PageMonLogs")
let LOG_FILE = LOG_DIR.appendingPathComponent("swift-fetcher-test-\(Date().timeIntervalSince1970).log")

// Create logs directory
try? FileManager.default.createDirectory(at: LOG_DIR, withIntermediateDirectories: true)

// Setup logging
func log(_ message: String) {
    print(message)
    // Append to log file
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

log("PageMon Direct Content Fetcher Test v\(VERSION)")
log("Started at: \(Date())")
log("Log file: \(LOG_FILE.path)")

// Parse command line arguments
var url = ""
var selector = ""
var verbose = false

var i = 1
while i < CommandLine.arguments.count {
    let arg = CommandLine.arguments[i]
    
    if arg.hasPrefix("--url=") {
        url = String(arg.dropFirst(6))
        i += 1
    } else if arg == "--url" && i + 1 < CommandLine.arguments.count {
        url = CommandLine.arguments[i + 1]
        i += 2
    } else if arg.hasPrefix("--selector=") {
        selector = String(arg.dropFirst(11))
        i += 1
    } else if arg == "--selector" && i + 1 < CommandLine.arguments.count {
        selector = CommandLine.arguments[i + 1]
        i += 2
    } else if arg == "--verbose" || arg == "-v" {
        verbose = true
        i += 1
    } else {
        i += 1
    }
}

if url.isEmpty || selector.isEmpty {
    log("Error: URL and selector are required")
    log("Usage: swift test-direct-fetcher.swift --url=URL --selector=SELECTOR [--verbose]")
    exit(1)
}

log("URL: \(url)")
log("Selector: \(selector)")
log("Verbose mode: \(verbose ? "enabled" : "disabled")")

// Check that URL is valid
guard let urlObj = URL(string: url) else {
    log("Error: Invalid URL format")
    exit(1)
}

// SwiftSoup for HTML parsing
// Since we can't import SwiftSoup directly in a script, we'll create a temporary package
let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("PageMonSwiftSoupTest-\(Int(Date().timeIntervalSince1970))")
try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

let packageSwift = """
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "PageMonTest",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "PageMonTest",
            dependencies: ["SwiftSoup"])
    ]
)
"""

let mainSwift = """
import Foundation
import SwiftSoup

// URL and selector from environment variables
let url = ProcessInfo.processInfo.environment["PAGEMON_URL"] ?? ""
let selector = ProcessInfo.processInfo.environment["PAGEMON_SELECTOR"] ?? ""
let verbose = ProcessInfo.processInfo.environment["PAGEMON_VERBOSE"] == "true"

// Function for logging
func log(_ message: String) {
    print(message)
}

if verbose {
    log("URL: \\(url)")
    log("Selector: \\(selector)")
}

// Check that URL is valid
guard let urlObj = URL(string: url) else {
    log("Error: Invalid URL format")
    exit(1)
}

do {
    // Create a URLSession configuration with a reasonable timeout
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60
    
    // Create the URL session
    let session = URLSession(configuration: config)
    
    if verbose {
        log("Fetching URL: \\(url)")
    }
    
    // Make the request
    let (data, response) = try await session.data(from: urlObj)
    
    // Check the response
    guard let httpResponse = response as? HTTPURLResponse else {
        log("Error: Not an HTTP response")
        exit(1)
    }
    
    if verbose {
        log("Received HTTP response with status code: \\(httpResponse.statusCode)")
    }
    
    // Check status code
    guard (200...299).contains(httpResponse.statusCode) else {
        log("HTTP error: \\(httpResponse.statusCode)")
        exit(1)
    }
    
    // Get the response body as a string
    guard let htmlString = String(data: data, encoding: .utf8) else {
        log("Error: Could not decode response data as UTF-8")
        exit(1)
    }
    
    log("Received HTML content (length: \\(htmlString.count) bytes)")
    
    // Parse the HTML using SwiftSoup
    do {
        // Parse the HTML
        let document = try SwiftSoup.parse(htmlString)
        if verbose {
            log("Successfully parsed HTML document with SwiftSoup")
        }
        
        // Try to select elements using the querySelector
        let elements = try document.select(selector)
        if verbose {
            log("Selected \\(elements.count) elements with selector: \\(selector)")
        }
        
        if elements.isEmpty() {
            log("No elements found matching selector: \\(selector)")
            exit(1)
        }
        
        // Get the first matching element
        let element = elements.first()!
        
        // Determine what content to extract based on element type
        var content = ""
        
        // Check if it's an image tag
        if element.tagName() == "img" {
            content = try element.attr("src")
            if verbose {
                log("Extracted image source URL from img tag")
            }
        }
        // Check if it's a link
        else if element.tagName() == "a" {
            let text = try element.text()
            let href = try element.attr("href")
            content = "\\(text) (\\(href))"
            if verbose {
                log("Extracted text and link from anchor tag")
            }
        }
        // Check if it has child elements and we want the full HTML
        else if !element.children().isEmpty() && selector.contains(":html") {
            content = try element.html()
            if verbose {
                log("Extracted HTML content from element")
            }
        }
        // Default to text content
        else {
            content = try element.text()
            if verbose {
                log("Extracted text content from element")
            }
        }
        
        // Clean the content
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Output the extracted content
        print("CONTENT_START")
        print(trimmedContent)
        print("CONTENT_END")
        
        if verbose {
            log("Content extraction completed successfully")
        }
    } catch let parseError as SwiftSoup.Exception {
        log("SwiftSoup error: \\(parseError.localizedDescription)")
        exit(1)
    } catch {
        log("Unexpected parsing error: \\(error.localizedDescription)")
        exit(1)
    }
} catch {
    log("Error fetching content: \\(error.localizedDescription)")
    exit(1)
}
"""

// Write files
let packagePath = tmpDir.appendingPathComponent("Package.swift")
let sourcesDir = tmpDir.appendingPathComponent("Sources/PageMonTest")
try? FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
let mainPath = sourcesDir.appendingPathComponent("main.swift")

try packageSwift.write(to: packagePath, atomically: true, encoding: .utf8)
try mainSwift.write(to: mainPath, atomically: true, encoding: .utf8)

// Change directory to the temporary package and resolve dependencies
log("Setting up temporary Swift package with SwiftSoup...")
let process = Process()
process.currentDirectoryURL = tmpDir
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = ["swift", "package", "resolve"]
process.launch()
process.waitUntilExit()

if process.terminationStatus != 0 {
    log("Error: Failed to resolve dependencies")
    exit(1)
}

// Build the package
log("Building package...")
let buildProcess = Process()
buildProcess.currentDirectoryURL = tmpDir
buildProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
buildProcess.arguments = ["swift", "build", "-c", "release"]
buildProcess.launch()
buildProcess.waitUntilExit()

if buildProcess.terminationStatus != 0 {
    log("Error: Failed to build package")
    exit(1)
}

// Run the built executable
log("Running content fetcher...")
let runProcess = Process()
runProcess.currentDirectoryURL = tmpDir
runProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
runProcess.arguments = ["\(tmpDir.path)/.build/release/PageMonTest"]

// Set environment variables
var environment = ProcessInfo.processInfo.environment
environment["PAGEMON_URL"] = url
environment["PAGEMON_SELECTOR"] = selector
environment["PAGEMON_VERBOSE"] = verbose ? "true" : "false"
runProcess.environment = environment

// Capture output
let outputPipe = Pipe()
runProcess.standardOutput = outputPipe
runProcess.standardError = outputPipe

runProcess.launch()
runProcess.waitUntilExit()

// Read the output
let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: outputData, encoding: .utf8) ?? ""

log("Process completed with exit code: \(runProcess.terminationStatus)")

// Extract content from output
if let contentStartIndex = output.range(of: "CONTENT_START\n")?.upperBound,
   let contentEndIndex = output.range(of: "\nCONTENT_END")?.lowerBound {
    let content = String(output[contentStartIndex..<contentEndIndex])
    log("Extracted content: \(content)")
} else {
    log("Failed to extract content from output")
    log("Raw output: \(output)")
}

// Clean up temporary directory
do {
    try FileManager.default.removeItem(at: tmpDir)
    if verbose {
        log("Temporary files removed")
    }
} catch {
    log("Warning: Failed to clean up temporary files: \(error.localizedDescription)")
}

log("Test completed at: \(Date())")
log("Log saved to: \(LOG_FILE.path)") 