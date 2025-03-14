//
//  PageMonApp.swift
//  PageMon
//
//  Created by Noah Zitsman on 3/13/25.
//

import SwiftUI

@main
struct PageMonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    setupLoggingDirectory()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.expanded)
        .commands {
            CommandGroup(replacing: .help) {
                Button("PageMon Help") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/noah/PageMon")!)
                }
            }
        }
    }
    
    // Make sure the logging directory exists
    private func setupLoggingDirectory() {
        let logsDir = FileManager.default.temporaryDirectory.appendingPathComponent("PageMonLogs")
        if !FileManager.default.fileExists(atPath: logsDir.path) {
            try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        }
    }
}
