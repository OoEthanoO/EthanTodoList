//
//  ContentView.swift
//  EthanToDoList-iOS
//
//  Created by Ethan Xu on 2025-04-11.
//

import SwiftUI
import SwiftData
import Foundation

extension Date: @retroactive RawRepresentable {
    public var rawValue: String {
        self.timeIntervalSinceReferenceDate.description
    }

    public init?(rawValue: String) {
        self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
    }
}

struct ContentView: View, ContentViewProtocol {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var items: [Item]
    
    @State private var selectedTab = 0
    @State private var showingAddTask = false
    @State private var showingTimeSettings = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate = Date()
    @State private var newTaskForSchool = true
    @State private var showRandomTaskAlert = false
    @State private var showPreviousTaskAlert = false
    @State private var showSumAlert = false
    @State private var showInfoAlert = false
    @State private var nextTask = ""
    
    @State private var isCustomGameTime = false
    @State private var autoAdjust = false
    @AppStorage("customGameTime") private var customGameTime = 0
    @AppStorage("lastGeneratedTask") var lastGeneratedTask: String = ""
    @AppStorage("homeTime") var homeTime: Date = Date()
    @AppStorage("sleepTime") var sleepTime: Date = Date()
    @AppStorage("wakeUpTime") var wakeUpTime: Date = Date()
    @AppStorage("offset") var offset: Int = 0
    @AppStorage("totalOffset") var totalOffset: Int = 0
    @AppStorage("halfTime") var halfTime: Bool = false
    @AppStorage("sleepTomorrow") var sleepTomorrow: Bool = false
    @AppStorage("numbers168String") private var numbers168String: String = ""
    @AppStorage("numbers90String") private var numbers90String: String = ""
    @AppStorage("numbersGenerationDate") private var numbersGenerationDate: Date = Date()
    @AppStorage("isTomorrow") var isTomorrow: Bool = false
    @AppStorage("extra") var extra: Int = 0
    @State private var pomodoroStreak: Int = 0
    
    @ObservedObject var timerManager: TimerManager
    
    @State var lastDeletedItem: Item?
    @State private var numbers168: [RandomNumber] = []
    @State private var numbers90: [RandomNumber] = []
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    var body: some View {
        // Find the TabView in ContentView.swift and modify it to include the Timer tab

        TabView(selection: $selectedTab) {
            // Tasks Tab
            NavigationStack {
                taskListView
                    .navigationTitle("Tasks")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                self.showingAddTask = true
                            }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            .tag(0)
            
            // Timer Tab
            NavigationStack {
                TimerView()
                    .navigationTitle("Timer")
            }
            .tabItem {
                Label("Timer", systemImage: "timer")
            }
            .tag(1)
            
            // Task Generator Tab
            // Generator Tab (renamed from Assistant)
            NavigationStack {
                numberGeneratorView
                    .navigationTitle("Generator")
            }
            .tabItem {
                Label("Generator", systemImage: "dice")
            }
            .tag(2)
            
            // Pomodoro Streak Tab (new)
            NavigationStack {
                pomodoroStreakView
                    .navigationTitle("Streaks")
            }
            .tabItem {
                Label("Streaks", systemImage: "flame")
            }
            .tag(3)
            
            // Settings Tab
            NavigationStack {
                settingsView
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(4)
        }
        .sheet(isPresented: $showingAddTask) {
            addTaskView
        }
        .sheet(isPresented: $showingTimeSettings) {
            timeSettingsView
        }
        .onAppear() {
            // Setup timer manager with SwiftData context and allocateTime function
            timerManager.setup(modelContext: modelContext) {
                self.allocateTime()
            }
            
            // Request notification permissions
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }
    
    // MARK: - ContentViewProtocol implementation
    func setLastDeletedItem(_ item: Item) {
        lastDeletedItem = item
    }
    
    // MARK: - Task List View
    private var taskListView: some View {
        VStack {
            let notCompletedTasks = items.filter { !$0.isCompleted }
            let isDoneForTodayTasks = notCompletedTasks.filter { $0.isDoneForToday ?? false }
            
            HStack {
                Text("\(isDoneForTodayTasks.count)/\(notCompletedTasks.count) completed today")
                    .font(.subheadline)
                
                Spacer()
                
                Button(action: {
                    for item in notCompletedTasks {
                        if !item.isForSchool {
                            item.isDoneForToday = true
                        }
                    }
                }) {
                    Text("Select All")
                        .font(.subheadline)
                }
                .padding(.trailing, 8)
                
                Button(action: {
                    for item in notCompletedTasks {
                        item.isDoneForToday = false
                        item.completedTime = 0
                    }
                }) {
                    Text("Clear All")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)

            List {
                ForEach(items.sorted(by: { $0.temporaryOrder < $1.temporaryOrder })) { item in
                    ItemView(item: item, items: items, contentView: self)
                }
                .onMove(perform: move)
            }
            
            // Add the Allocate button
            Button(action: allocateTime) {
                Label("Allocate Time", systemImage: "timer")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            if lastDeletedItem != nil {
                Button("Undo Delete") {
                    undoDelete()
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 8)
            }
        }
    }
    
    // MARK: - Number Generator View (separated from task generator)
    private var numberGeneratorView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        generateRandomNumbers()
                    }
                }) {
                    Label("Generate Random Numbers", systemImage: "dice")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                if !numbers168String.isEmpty {
                    SimpleNumbersView(
                        title: "Numbers (1-168):",
                        numbers: numbers168String,
                        lastGenerated: numbersGenerationDate
                    )
                }

                if !numbers90String.isEmpty {
                    SimpleNumbersView(
                        title: "Numbers (1-90):",
                        numbers: numbers90String,
                        lastGenerated: numbersGenerationDate
                    )
                }
            }
            .padding(.top)
        }
    }

    // MARK: - Pomodoro Streak View (new dedicated tab)
    private var pomodoroStreakView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pomodoro Streak Counter
                VStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .frame(width: 60, height: 80)
                        .foregroundStyle(.orange)
                        .padding(.top)
                    
                    Text("Pomodoro Streak")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Track your focus sessions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            // Use withAnimation to properly handle state change
                            withAnimation {
                                if pomodoroStreak > 0 {
                                    DispatchQueue.main.async {
                                        pomodoroStreak -= 1
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                        }
//                        
                        Text("\(pomodoroStreak)")
                            .font(.system(size: 72, weight: .bold))
                            .frame(minWidth: 120)
                        
                        Button(action: {
                            // Use withAnimation to properly handle state change
                            withAnimation {
                                DispatchQueue.main.async {
                                    pomodoroStreak += 1
                                }
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Streak status message
                    Group {
                        if pomodoroStreak == 0 {
                            Text("Start your streak today!")
                                .foregroundColor(.secondary)
                        } else if pomodoroStreak < 3 {
                            Text("Keep going! You're building momentum.")
                                .foregroundColor(.blue)
                        } else if pomodoroStreak < 7 {
                            Text("Great work! Take a longer break on your next rest.")
                                .foregroundColor(.orange)
                        } else {
                            Text("Amazing streak! You're a focus master.")
                                .foregroundColor(.purple)
                        }
                    }
                    .font(.headline)
                    .padding(.vertical)
                    .multilineTextAlignment(.center)
                    
                    Button("Reset Streak") {
                        // Add confirmation dialog
                        // For now just reset directly
                        pomodoroStreak = 0
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
                .padding(.horizontal)
//                .shadow(radius: 2)
                
                // Tips section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Pomodoro Technique")
                        .font(.headline)
                    
                    Text("1. Work for 25 minutes")
                    Text("2. Take a 5 minute break")
                    Text("3. After 4 sessions, take a longer 15-30 minute break")
                    Text("4. Each completed session adds to your streak!")
                    
                    Text("A consistent streak helps build lasting focus habits.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        Form {
            Section("Time Settings") {
                DatePicker("Sleep Time", selection: $sleepTime, displayedComponents: .hourAndMinute)
                    .padding(.vertical, 4)
                
                Toggle("Sleep Tomorrow", isOn: $sleepTomorrow)
                    .padding(.vertical, 4)
                
                Toggle("Is Tomorrow", isOn: $isTomorrow)
                    .padding(.vertical, 4)
                
                HStack {
                    Text("Offset")
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Button("+100") {
                            offset = min(offset + 100, 1440)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 100)
                        .foregroundStyle(.blue)
                        
                        Button("+50") {
                            offset = min(offset + 50, 1440)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 100)
                        .foregroundStyle(.blue)
                        
                        Button("0") {
                            offset = 0
                        }
                        .buttonStyle(.plain)
                        .frame(width: 100)
                        .foregroundStyle(.blue)
                        
                        Button("-50") {
                            offset = max(offset - 50, 0)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 100)
                        .foregroundStyle(.blue)
                        
                        Button("-100") {
                            offset = max(offset - 100, 0)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 100)
                        .foregroundStyle(.blue)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: $offset) {
                        ForEach(0...1440, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()
                    .labelsHidden()
                }
                .padding(.vertical, 4)
            }
            
            
                
                
//                HStack {
//                    Text("Extra")
//                    
//                    Spacer()
//                    
//                    Picker("", selection: $extra) {
//                        ForEach(0...1440, id: \.self) { value in
//                            Text("\(value)").tag(value)
//                        }
//                    }
//                    .pickerStyle(.wheel)
//                    .frame(width: 80, height: 100)
//                    .clipped()
//                    .labelsHidden()
//                }
//                .padding(.vertical, 4)
        }
    }
    
    // MARK: - Add Task View
    private var addTaskView: some View {
        NavigationStack {
            Form {
                TextField("Task Title", text: $newTaskTitle)
                    .submitLabel(.next)
                    .textInputAutocapitalization(.words)
                
                DatePicker("Due Date", selection: $newTaskDueDate, displayedComponents: .date)
                
                Toggle("For school", isOn: $newTaskForSchool)
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        self.showingAddTask = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !newTaskTitle.isEmpty {
                            self.showingAddTask = false
                            addItem()
                        }
                    }
                    .disabled(newTaskTitle.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Time Settings View
    private var timeSettingsView: some View {
        NavigationStack {
            Form {
                Section("Time Offsets") {
                    HStack {
                        Text("Total Offset")
                        Spacer()
                        TextField("", value: $totalOffset, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Offset")
                        Spacer()
                        TextField("", value: $offset, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section("Schedule Times") {
                    DatePicker("Home Time", selection: $homeTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("Sleep Time", selection: $sleepTime, displayedComponents: .hourAndMinute)
                    
                    Toggle("Sleep Tomorrow", isOn: $sleepTomorrow)
                    
                    Toggle("Half Time", isOn: $halfTime)
                    
                    if halfTime {
                        Text("Half time: \(timeFormatter.string(from: getMiddleTime()))")
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker("Wake Up Time", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Time Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        self.showingTimeSettings = false
                    }
                }
            }
        }
    }
    
    // MARK: - Include all helper functions from the original app
    // I'm including a few key functions below, but you should include all the helper functions
    // from your macOS app to maintain full functionality
    
    private func addItem() {
        withAnimation {
            let newItem = Item(name: newTaskTitle, dueDate: newTaskDueDate,
                             isForSchool: newTaskForSchool, isCompleted: false)
            // Set temporaryOrder to place at the end
            newItem.temporaryOrder = items.count
            modelContext.insert(newItem)
            newTaskTitle = ""
            newTaskDueDate = Date()
            newTaskForSchool = true
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        withAnimation {
            // Get the sourceIndex
            let sourceIndex = source.first!
            
            // Find the item with temporaryOrder equal to sourceIndex
            var sourceItem: Item?
            for item in items {
                if item.temporaryOrder == sourceIndex {
                    sourceItem = item
                    break
                }
            }
            
            guard let sourceItem = sourceItem else { return }
            
            if sourceIndex < destination {
                // Moving downward
                for item in items {
                    if item.temporaryOrder < destination && item.temporaryOrder > sourceIndex {
                        item.temporaryOrder -= 1
                    }
                }
                sourceItem.temporaryOrder = destination - 1
            } else if sourceIndex > destination {
                // Moving upward
                for item in items {
                    if item.temporaryOrder >= destination && item.temporaryOrder < sourceIndex {
                        item.temporaryOrder += 1
                    }
                }
                sourceItem.temporaryOrder = destination
            }
            
            // Save the changes to the model context
            do {
                try modelContext.save()
            } catch {
                print("Failed to save reordering: \(error)")
            }
        }
    }
    
//    func sortByOrder(item1: Item, item2: Item) -> Bool {
//        return item1.order <= item2.order
//    }
    
    func undoDelete() {
        if let lastDeletedItem = lastDeletedItem {
            // Set the temporaryOrder to place the item at the end of the list
            lastDeletedItem.temporaryOrder = items.count
            
            // Insert the item back into the model context
            modelContext.insert(lastDeletedItem)
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to save model context: \(error)")
            }
            
            self.lastDeletedItem = nil
        }
    }
    
    // Add all your remaining helper functions: removeSeconds, removeHours,
    // updateToToday, getSum, getMiddleTime, getInformation, etc.
    
    // Here are some examples of the key ones:
    func removeSeconds(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return calendar.date(from: components) ?? date
    }
    
    func removeHours(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
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
    
    // Copy all remaining functions...

    private func generateRandomTask() {
        // Your existing random task generation logic
//        var sum: Double = getSum()
        // Copy the remaining implementation...
    }
    
    private func getMiddleTime() -> Date {
        // Implementation from macOS app
        let timeBetweenHomeAndSleep: Int = (Calendar.current.dateComponents([.minute], from: removeSeconds(from: homeTime), to: removeSeconds(from: sleepTime)).minute ?? 0)
        
        var middleTime = Calendar.current.date(byAdding: .minute, value: -(timeBetweenHomeAndSleep / 2), to: sleepTime)
        middleTime = updateToToday(date: middleTime!)
        
        return middleTime!
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
    
    private func getInformation() -> (Int, Date, Int, Date, Date) {
        // Copy your existing getInformation implementation
        // This is where you calculate code time, game time, etc.
        homeTime = updateToToday(date: homeTime)
        sleepTime = updateToToday(date: sleepTime, tomorrow: sleepTomorrow)
        
        // Add the rest of the implementation...
        // Simplified example:
//        let curHomeTime = homeTime
//        let curSleepTime = sleepTime
        
        // Rest of implementation from macOS version
        
        // Placeholder return:
        return (0, sleepTime, 0, Date(), Date())
    }
    
    private func generateRandomNumbers() {
        // Generate 10 random numbers from 1 to 168
        let randomNumbers168 = (0..<10).map { _ in
            Int.random(in: 1...168)
        }
        numbers168String = randomNumbers168.map { "\($0)" }.joined(separator: ", ")
        
        // Generate 10 random numbers from 1 to 90
        let randomNumbers90 = (0..<10).map { _ in
            Int.random(in: 1...90)
        }
        numbers90String = randomNumbers90.map { "\($0)" }.joined(separator: ", ")
        
        // Update timestamp
        numbersGenerationDate = Date()
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func allocateTime() {
        let sum = getSum()
        
        let calculationSleepTime = updateToToday(date: sleepTime, tomorrow: sleepTomorrow)
        
        let rightNow = updateToToday(date: Date(), tomorrow: isTomorrow)
        
        for item in items {
            if item.isDoneForToday! {
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
    
//    private func loadSavedNumbers() {
//        if let decoded168 = try? JSONDecoder().decode([RandomNumber].self, from: randomNumbers168Crossed) {
//            numbers168 = decoded168
//        }
//        if let decoded90 = try? JSONDecoder().decode([RandomNumber].self, from: randomNumbers90Crossed) {
//            numbers90 = decoded90
//        }
//    }
}

//#Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
//}
