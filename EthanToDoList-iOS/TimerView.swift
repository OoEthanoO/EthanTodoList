import SwiftUI
import SwiftData
import Combine

// For persistent timer storage
class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var startTime: Date?
    @Published var endTime: Date?
    @Published var currentTask: Item?
    @Published var showCompletionSheet = false
    
    @Query private var items: [Item]
    
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
        
//        allocateTimeHandler?()
        
//        allocateTime()
        
        
        // Find task with lowest temporaryOrder that isn't completed or done for today
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { item in
                !item.isCompleted && !(item.isDoneForToday ?? false) && ((item.currentMinutes ?? 0) != 0)
            },
            sortBy: [SortDescriptor(\.temporaryOrder)]
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
        guard isRunning, let startTime = startTime, let task = currentTask else { return }
        
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
        // Request notification permission with critical alerts if needed
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
        
        // Critical alert - requires special entitlement from Apple
        content.interruptionLevel = .critical
        
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
        // Schedule 5 notifications 1 minute apart to simulate sustained alarm
        for i in 1...5 {
            let content = UNMutableNotificationContent()
            content.title = "Timer Still Complete!"
            content.body = "Your task \"\(taskName ?? "")\" needs attention!"
            content.sound = UNNotificationSound.default
            content.interruptionLevel = .critical
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

// Task completion view that shows when a timer completes
struct TimerCompletionView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.green)
                
                Text("Task Complete!")
                    .font(.system(size: 24, weight: .bold))
                
                if let task = timerManager.currentTask {
                    Text(task.name)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    withAnimation {
                        timerManager.showCompletionSheet = false
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
            .padding(30)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(30)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
        .edgesIgnoringSafeArea(.all)
    }
}

// Main timer view
struct TimerView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    // UI state
    @State private var buttonScale: CGFloat = 1.0
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    @AppStorage("sleepTime") var sleepTime: Date = Date()
    @AppStorage("sleepTomorrow") var sleepTomorrow: Bool = false
    @AppStorage("isTomorrow") var isTomorrow: Bool = false
    @AppStorage("offset") var offset: Int = 0
    @AppStorage("extra") var extra: Int = 0
    
    @Query private var items: [Item]
    
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            // Task info area
            if let task = timerManager.currentTask {
                taskInfoView(task: task)
            } else {
                noTaskSelectedView()
            }
            
            Spacer()
            
            // Timer display
            ZStack {
                Circle()
                    .stroke(
                        Color.gray.opacity(0.2),
                        lineWidth: 15
                    )
                    .frame(width: 250, height: 250)
                
                if timerManager.isRunning {
                    timerProgressView()
                }
                
                timerDisplayView()
            }
            .padding(.vertical, 40)
            
            Spacer()
            
            // Control buttons
            timerControlButtons()
        }
        .padding()
        .onAppear {
            // Check if timer completed while in background
            
            if timerManager.isRunning,
               let endTime = timerManager.endTime,
               Date() >= endTime {
                timerManager.completeTask()
            }
        }
    }
    
    // MARK: - Component Views
    
    private func taskInfoView(task: Item) -> some View {
        VStack(spacing: 12) {
            Text("Current Task")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(task.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack {
                Text("Progress:")
                    .foregroundColor(.secondary)
                
                Text("\(task.completedTime ?? 0)/\(task.currentMinutes ?? 0) min")
                    .fontWeight(.medium)
            }
            .padding(.top, 4)
            
            if timerManager.isRunning {
                Text("Task will complete at \(formatTime(timerManager.endTime!))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func noTaskSelectedView() -> some View {
        VStack(spacing: 12) {
            Text("No Active Task")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Press start to begin working on the next task")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func timerProgressView() -> some View {
        Circle()
            .trim(from: 0, to: min(1.0, progressFraction))
            .stroke(
                Color.blue,
                style: StrokeStyle(
                    lineWidth: 15,
                    lineCap: .round
                )
            )
            .frame(width: 250, height: 250)
            .rotationEffect(.degrees(-90))
            .animation(.linear, value: progressFraction)
    }
    
    private func timerDisplayView() -> some View {
        VStack {
            if timerManager.isRunning {
                Text(hours > 0 ? "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))" :
                               "\(minutes):\(String(format: "%02d", seconds))")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .onReceive(timer) { _ in
                        let (hours, minutes, seconds) = timerManager.calculateRemainingTime()
                        self.hours = hours
                        self.minutes = minutes
                        self.seconds = seconds
//                        print("\(minutes):\(String(format: "%02d", seconds))")
                    }
                
                Text("Remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Ready")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func timerControlButtons() -> some View {
        HStack(spacing: 30) {
            if timerManager.isRunning {
                Button(action: {
                    withAnimation(.spring()) {
                        buttonScale = 0.9
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            buttonScale = 1.0
                            timerManager.stopTimer()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 140)
                    .background(Color.red)
                    .cornerRadius(15)
                }
                .scaleEffect(buttonScale)
            } else {
                Button(action: {
                    withAnimation(.spring()) {
                        buttonScale = 0.9
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            buttonScale = 1.0
                            allocateTime()
                            timerManager.startTimer()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 140)
                    .background(Color.green)
                    .cornerRadius(15)
                }
                .scaleEffect(buttonScale)
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Helper Properties & Methods
    
    private var progressFraction: CGFloat {
        guard timerManager.isRunning,
              let startTime = timerManager.startTime,
              let endTime = timerManager.endTime else {
            return 0
        }
        
        let totalDuration = endTime.timeIntervalSince(startTime)
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        return CGFloat(elapsedTime / totalDuration)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func allocateTime() {
        let sum = getSum()
        
        sleepTime = updateToToday(date: sleepTime, tomorrow: sleepTomorrow)
        
        let rightNow = updateToToday(date: Date(), tomorrow: isTomorrow)
        
        for item in items {
            if item.isDoneForToday! || item.currentMinutes ?? 0 <= item.completedTime ?? 0 {
                item.currentMinutes = 0
                continue
            }
            
            item.dueDate = removeHours(from: item.dueDate)
            
            let days = (Calendar.current.dateComponents([.day], from: removeHours(from: Date()), to: item.dueDate).day ?? 0)
            var doubleDays: Double = 0
            if days > 0 {
                doubleDays = Double(days)
            } else {
                doubleDays = 1 / (Double(days) + 2)
            }
            
            var fraction: Double = 1 / doubleDays
            fraction *= (item.isForSchool ? 1 : 0.1)
            
            var totalWorkMinutes: Int = (Calendar.current.dateComponents([.minute], from: rightNow, to: sleepTime).minute ?? 0) - offset - extra
            
            for item in items {
                if !item.isDoneForToday! {
                    totalWorkMinutes += min(item.currentMinutes ?? 0, item.completedTime ?? 0)
                }
            }
            
            let workMinutes: Int = max(Int((fraction / sum) * Double(totalWorkMinutes)), 0)
            
            item.currentMinutes = workMinutes
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save model context: \(error)")
        }
    }
    
    func removeHours(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func updateToToday(date: Date, tomorrow: Bool = false) -> Date {
        // Implementation from macOS app
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        if (tomorrow) {
            return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: Date().addingTimeInterval(86400))!
        }
        return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: Date())!
    }
    
    private func getSum() -> Double {
        // Your existing getSum implementation
        var sum: Double = 0
        for item in items {
            if item.isDoneForToday! {
                continue
            }
            
            item.dueDate = removeHours(from: item.dueDate)
            
            let days = (Calendar.current.dateComponents([.day], from: removeHours(from: Date()), to: item.dueDate).day ?? 0)
            var doubleDays: Double = 0
            if days > 0 {
                doubleDays = Double(days)
            } else {
                doubleDays = 1 / (Double(days) + 2)
            }
            
            var value: Double = 1 / doubleDays
            value *= (item.isForSchool ? 1 : 0.1)
            sum += value
        }
        
        return sum
    }
}

// Custom checkbox toggle style
//struct CheckboxToggleStyle: ToggleStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        HStack {
//            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
//                .resizable()
//                .frame(width: 22, height: 22)
//                .foregroundColor(configuration.isOn ? .blue : .gray)
//                .onTapGesture {
//                    configuration.isOn.toggle()
//                }
//            configuration.label
//        }
//    }
//}

//#Preview {
//    TimerView()
//        .environmentObject(TimerManager())
//}
