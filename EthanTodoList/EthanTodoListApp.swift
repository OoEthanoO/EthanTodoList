import SwiftUI
import SwiftData
import UserNotifications
import BackgroundTasks

@main
struct EthanToDoListApp: App {
    @StateObject private var timerManager = TimerManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var sidebarSelection: Int? = 1

    var body: some Scene {
        WindowGroup {
            MainView(timerManager: timerManager, sidebarSelection: $sidebarSelection)
                .modelContainer(sharedModelContainer)
                .environmentObject(timerManager)
                .onAppear {
                    // Setup timer manager with SwiftData context
                    timerManager.setup(modelContext: sharedModelContainer.mainContext)
                    
                    // Request notification permissions
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Add menu commands
            SidebarCommands()
            
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: Notification.Name("NewTask"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandMenu("Tasks") {
                Button("Allocate Time") {
                    NotificationCenter.default.post(name: Notification.Name("AllocateTime"), object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
                
                Divider()
                
                Button("Mark All Non-School Tasks Complete") {
                    NotificationCenter.default.post(name: Notification.Name("SelectAllNonSchool"), object: nil)
                }
                
                Button("Clear All Daily Progress") {
                    NotificationCenter.default.post(name: Notification.Name("ClearAllDaily"), object: nil)
                }
            }
            
            CommandMenu("Timer") {
                Button("Start Timer") {
                    self.sidebarSelection = 2
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.timerManager.startTimer()
                    }
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])
                
                Button("Stop Timer") {
                    self.timerManager.stopTimer()
                }
                .keyboardShortcut("0", modifiers: [.command, .shift])
                
                Button("Complete Task") {
                    self.timerManager.completeTask()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
            
            CommandMenu("View") {
                Button("Tasks") {
                    self.sidebarSelection = 1
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Timer") {
                    self.sidebarSelection = 2
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Time Splits") {
                    self.sidebarSelection = 3
                }
                .keyboardShortcut("3", modifiers: .command)
                
                Button("Number Generator") {
                    self.sidebarSelection = 4
                }
                .keyboardShortcut("4", modifiers: .command)
                
                Button("Data") {
                    self.sidebarSelection = 5
                }
                .keyboardShortcut("5", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }
    }
}
