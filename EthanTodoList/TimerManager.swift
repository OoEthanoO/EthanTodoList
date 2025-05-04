import SwiftUI
import SwiftData
import Combine
import UserNotifications

enum TaskSelectionMode: String, CaseIterable, Identifiable {
    case highestOrder = "Priority Order"
    case highestTime = "Highest Time"
    
    var id: String { self.rawValue }
}

class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var startTime: Date?
    @Published var endTime: Date?
    @Published var currentTask: Item?
    @Published var showCompletionSheet = false
    @Published var taskSelectionMode: TaskSelectionMode = .highestOrder
    
    private var modelContext: ModelContext?
    var allocateTimeHandler: (() -> Void)?
    
    func setup(modelContext: ModelContext, allocateTimeHandler: (() -> Void)? = nil) {
        self.modelContext = modelContext
        self.allocateTimeHandler = allocateTimeHandler
        
        // Restore state if app was closed with active timer
        let storage = PersistentTimerStorage.shared
        if storage.isTimerActive, let endTime = storage.endTime {
            self.isRunning = true
            self.startTime = storage.startTime
            self.endTime = endTime
            
            // Try to find the task
            if let taskName = storage.taskName, let context = self.modelContext {
                let descriptor = FetchDescriptor<Item>(predicate: #Predicate { item in
                    item.name == taskName
                })
                if let items = try? context.fetch(descriptor), let item = items.first {
                    self.currentTask = item
                }
            }
            
            // Check if timer completed while app was in background
            if storage.completedInBackground {
                completeTask()
                storage.completedInBackground = false
            }
        }
    }
    
    func startTimer() {
        guard let modelContext = modelContext, !isRunning else { return }
        
        // Define sort descriptors based on selection mode
        var sortDescriptors: [SortDescriptor<Item>]
        
        switch taskSelectionMode {
        case .highestOrder:
            sortDescriptors = [SortDescriptor(\.temporaryOrder)]
        case .highestTime:
            sortDescriptors = [
                SortDescriptor(\.currentMinutes, order: .reverse),
                SortDescriptor(\.temporaryOrder)
            ]
        }
        
        // Find task based on selected criteria
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { item in
                !item.isCompleted && !(item.isDoneForToday ?? false) && ((item.currentMinutes ?? 0) != 0)
            },
            sortBy: sortDescriptors
        )
        
        guard let tasks = try? modelContext.fetch(descriptor), let task = tasks.first else {
            return // No tasks available
        }
        
        // Calculate duration: currentMinutes - completedTime
        let remainingMinutes = (task.currentMinutes ?? 0) - (task.completedTime ?? 0)
        guard remainingMinutes > 0 else { return }
        
        // Set up the timer
        startTime = Date()
        endTime = Date().addingTimeInterval(Double(remainingMinutes) * 60)
        currentTask = task
        isRunning = true
        
        // Store persistently
        let storage = PersistentTimerStorage.shared
        storage.isTimerActive = true
        storage.taskName = task.name
        storage.startTime = startTime
        storage.endTime = endTime
        storage.notificationSent = false
        
        // Schedule notification for when timer completes
        scheduleCompletionNotification(task: task, duration: remainingMinutes)
    }
    
    func stopTimer() {
        guard isRunning, let startTime = startTime, let task = currentTask else {
            AlarmManager.shared.cancelAllAlarms()
            reset()
            return
        }
        
        // Calculate elapsed minutes
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        let elapsedMinutes = elapsedSeconds / 60 // At least 1 minute
        
        // Update task's completedTime
        task.completedTime = (task.completedTime ?? 0) + elapsedMinutes
        
        // Check if task is now complete
        if task.completedTime ?? 0 >= task.currentMinutes ?? 0 {
            showCompletionSheet = true
        }
        
        // Save changes
        try? modelContext?.save()
        
        // Reset timer
        AlarmManager.shared.cancelAllAlarms()
        reset()
    }
    
    func completeTask() {
        guard isRunning, let startTime = startTime, let task = currentTask else { return }
        
        // Mark task as done for today
        task.isDoneForToday = true
        try? modelContext?.save()
        
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        let elapsedMinutes = elapsedSeconds / 60 // At least 1 minute
        
        task.completedTime = (task.completedTime ?? 0) + elapsedMinutes
        
        // Show completion UI
        showCompletionSheet = true
        
        AlarmManager.shared.cancelAllAlarms()
        
        // Reset timer
        reset()
    }
    
    func reset() {
        isRunning = false
        startTime = nil
        endTime = nil
        
        // Clear persistent storage
        let storage = PersistentTimerStorage.shared
        storage.isTimerActive = false
        storage.taskName = nil
        storage.startTime = nil
        storage.endTime = nil
        storage.notificationSent = false
    }
    
    private func scheduleCompletionNotification(task: Item, duration: Int) {
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
            guard granted else { return }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Timer Complete"
            content.body = "Your task \"\(task.name)\" is complete!"
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = "TIMER_COMPLETED"
            
            // Create trigger for when timer ends
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(duration * 60), repeats: false)
            
            // Create request
            let request = UNNotificationRequest(
                identifier: "timer-completion",
                content: content,
                trigger: trigger
            )
            
            // Schedule notification
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func calculateElapsedMinutes() -> Int {
        guard let startTime = startTime else { return 0 }
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        return max(0, elapsedSeconds / 60)
    }
    
    func calculateRemainingTime() -> (Int, Int, Int) {
        guard let endTime = endTime, isRunning else { return (0, 0, 0) }
        
        let remainingSeconds = max(0, Int(endTime.timeIntervalSince(Date())))
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60
        
        return (hours, minutes, seconds)
    }
}

// For persisting timer state between app launches
class PersistentTimerStorage {
    static let shared = PersistentTimerStorage()
    
    var isTimerActive: Bool {
        get { UserDefaults.standard.bool(forKey: "timer_active") }
        set { UserDefaults.standard.set(newValue, forKey: "timer_active") }
    }
    
    var taskName: String? {
        get { UserDefaults.standard.string(forKey: "timer_task_name") }
        set { UserDefaults.standard.set(newValue, forKey: "timer_task_name") }
    }
    
    var startTime: Date? {
        get { UserDefaults.standard.object(forKey: "timer_start_time") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "timer_start_time") }
    }
    
    var endTime: Date? {
        get { UserDefaults.standard.object(forKey: "timer_end_time") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "timer_end_time") }
    }
    
    var notificationSent: Bool {
        get { UserDefaults.standard.bool(forKey: "timer_notification_sent") }
        set { UserDefaults.standard.set(newValue, forKey: "timer_notification_sent") }
    }
    
    var completedInBackground: Bool {
        get { UserDefaults.standard.bool(forKey: "timer_completed_background") }
        set { UserDefaults.standard.set(newValue, forKey: "timer_completed_background") }
    }
}

// For notification handling
class AlarmManager {
    static let shared = AlarmManager()
    
    func scheduleImmediateAlarm(taskName: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "Your task \"\(taskName ?? "")\" is complete!"
        content.sound = UNNotificationSound.default
        
        // Set category for action buttons
        content.categoryIdentifier = "TIMER_COMPLETED"
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "immediate-timer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        
        // Schedule repeating notifications as backup
        scheduleRepeatingAlarms(taskName: taskName)
    }
    
    func scheduleRepeatingAlarms(taskName: String?) {
        // Schedule notifications 1 minute apart
        for i in 1...3 {
            let content = UNMutableNotificationContent()
            content.title = "Timer Still Complete!"
            content.body = "Your task \"\(taskName ?? "")\" needs attention!"
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = "TIMER_COMPLETED"
            
            // Trigger with increasing delay
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(i * 60), repeats: false)
            
            let request = UNNotificationRequest(identifier: "repeating-timer-\(i)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func cancelAllAlarms() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
