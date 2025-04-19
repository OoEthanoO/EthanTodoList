import SwiftUI
import SwiftData
import UserNotifications
import BackgroundTasks

@main
struct EthanToDoList_iOSApp: App {
    @StateObject private var timerManager = TimerManager()
        
    init() {
        // Register for background processing using a static handler
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.ethanyanxu.EthanToDoList-iOS.timer-refresh",
            using: nil
        ) { task in
            Self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Set up notification categories
        let stopAction = UNNotificationAction(
            identifier: "STOP_TIMER",
            title: "Stop Timer",
            options: .foreground
        )
        
        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_COMPLETED",
            actions: [stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([timerCategory])
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
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
            ZStack {
                ContentView(timerManager: timerManager)
                    .modelContainer(sharedModelContainer)
                    .environmentObject(timerManager)
                    .onAppear {
//                        // Setup timer manager with SwiftData context
//                        timerManager.setup(modelContext: sharedModelContainer.mainContext)
//                        
//                        // Request notification permissions
//                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                    }
                
                // Show completion sheet as an overlay
                if timerManager.showCompletionSheet {
                    TimerCompletionView()
                        .environmentObject(timerManager)
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .animation(.easeInOut, value: timerManager.showCompletionSheet)
        }
    }
    
    // Static background refresh handler
    private static func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleBackgroundRefresh()
        
        // Check if any timers need to be completed
        checkTimerCompletion()
        
        // Task completed successfully
        task.setTaskCompleted(success: true)
    }
    
    // Schedule next background refresh
    private static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ethanyanxu.EthanToDoList-iOS.timer-refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // Run after 60 seconds
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    // Check if any timers need to be completed
    private static func checkTimerCompletion() {
        let storage = PersistentTimerStorage.shared
        
        // If timer exists and has ended
        if storage.isTimerActive && storage.endTime != nil && storage.endTime! <= Date() {
            // Mark task as completed
            // Note: Can't directly modify SwiftData from here without a ModelContext
            // Instead, set a flag that the timer completed in background
            storage.completedInBackground = true
            
            // Schedule an immediate notification if not already sent
            if !storage.notificationSent {
                AlarmManager.shared.scheduleImmediateAlarm(taskName: storage.taskName)
                storage.notificationSent = true
            }
        }
    }
}
