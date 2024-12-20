//
//  EthanTodoListApp.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2024-04-22.
//

import SwiftUI
import SwiftData

@main
struct EthanTodoListApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Class.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Show Logs") {
                    showLogWindow()
                }
                .keyboardShortcut("L", modifiers: [.command])
            }
        }
    }
    
    private func showLogWindow() {
        let logWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        logWindow.center()
        logWindow.setFrameAutosaveName("Log Window")
        logWindow.contentView = NSHostingView(rootView: LogView(logManager: LogManager.shared))
        logWindow.makeKeyAndOrderFront(nil)
    }
}
