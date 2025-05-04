import SwiftUI
import SwiftData

struct TaskListView: View, ContentViewProtocol {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var lastDeletedItem: Item?
    @EnvironmentObject var timerManager: TimerManager
    
    // Context menu items require different handling in macOS
    @State private var selectedItems: Set<Item.ID> = []
    
    var body: some View {
        VStack {
            // Status bar
            HStack {
                let notCompletedTasks = items.filter { !$0.isCompleted }
                let isDoneForTodayTasks = notCompletedTasks.filter { $0.isDoneForToday ?? false }
                
                Text("\(isDoneForTodayTasks.count)/\(notCompletedTasks.count) completed today")
                    .font(.headline)
                
                Spacer()
                
                Button("Mark Non-School Tasks Complete") {
                    markNonSchoolTasksComplete()
                }
                .buttonStyle(.link)
                .padding(.trailing, 12)
                
                Button("Clear Daily Progress") {
                    clearAllDailyProgress()
                }
                .buttonStyle(.link)
            }
            .padding([.horizontal, .top])
            
            // Task list
            Table(items.sorted(by: { $0.temporaryOrder < $1.temporaryOrder }), selection: $selectedItems) {
                TableColumn("Status") { item in
                    HStack {
                        Button(action: {
                            item.isCompleted.toggle()
                            item.isDoneForToday = item.isCompleted
                        }) {
                            Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                .foregroundColor(item.isCompleted ? .blue : .gray)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            if !item.isCompleted {
                                item.isDoneForToday?.toggle()
                            }
                        }) {
                            Image(systemName: (item.isDoneForToday ?? false) ? "checkmark.square.fill" : "square")
                                .foregroundColor((item.isDoneForToday ?? false) ? .blue : .gray)
                        }
                        .buttonStyle(.plain)
                        .disabled(item.isCompleted)
                    }
                }
                .width(70)

                TableColumn("Task") { item in
                    Text(item.name)
                        .foregroundStyle(item.isCompleted ? Color.gray : (item.isForSchool ? Color.red : Color.primary))
                        .strikethrough(item.isCompleted)
                }

                TableColumn("Due Date") { item in
                    CustomDateText(date: item.dueDate, isCompleted: item.isCompleted)
                }
                .width(100)
                
                TableColumn("Notes") { item in
                    if let notes = item.notes, !notes.isEmpty {
                        Text(notes)
                            .lineLimit(1)
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                    }
                }
                
                TableColumn("Time") { item in
                    if item.currentMinutes ?? 0 > 0 {
                        if let completedTime = item.completedTime, completedTime > 0 {
                            Text("\(completedTime)/\(item.currentMinutes ?? 0) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(item.currentMinutes ?? 0) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .width(80)
            }
            .contextMenu(forSelectionType: Item.ID.self) { selectedItems in
                if let selectedItem = selectedItems.first.flatMap({ id in
                    items.first(where: { $0.id == id })
                }) {
                    Button("Edit") {
                        editItem(selectedItem)
                    }
                    
                    Button("Delete") {
                        deleteItem(selectedItem)
                    }
                }
            }
            
            // Allocate button
            Button(action: allocateTime) {
                Label("Allocate Time", systemImage: "timer")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding([.horizontal, .bottom])
            
            if lastDeletedItem != nil {
                Button("Undo Delete") {
                    undoDelete()
                }
                .buttonStyle(.bordered)
                .padding(.bottom)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SelectAllNonSchool"))) { _ in
            markNonSchoolTasksComplete()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ClearAllDaily"))) { _ in
            clearAllDailyProgress()
        }
    }
    
    // MARK: - ContentViewProtocol implementation
    func setLastDeletedItem(_ item: Item) {
        lastDeletedItem = item
    }
    
    func allocateTime() {
        let sum = getSum()
        
        let sleepTime = updateToToday(date: UserDefaults.standard.object(forKey: "sleepTime") as? Date ?? Date())
        let offset = UserDefaults.standard.integer(forKey: "offset")
        let extra = UserDefaults.standard.integer(forKey: "extra")
        
        let rightNow = Date()
        
        for item in items {
            if item.isDoneForToday! || item.isCompleted {
                item.currentMinutes = 0
                continue
            }
            
            let itemDueDate = removeHours(from: item.dueDate)
            
            let days = (Calendar.current.dateComponents([.day], from: removeHours(from: Date()), to: itemDueDate).day ?? 0)
            var doubleDays: Double = 0
            if days > 0 {
                doubleDays = Double(days)
            } else {
                doubleDays = 1 / (Double(abs(days)) + 2)
            }
            
            var fraction: Double = 1 / doubleDays
            fraction *= (item.isForSchool ? 1 : 0.1)
            
            var totalWorkMinutes: Int = (Calendar.current.dateComponents([.minute], from: rightNow, to: sleepTime).minute ?? 0) - offset - extra
            
            for item in items {
                if !item.isDoneForToday! && !item.isCompleted {
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
    
    // MARK: - Helper methods
    
    private func markNonSchoolTasksComplete() {
        let notCompletedTasks = items.filter { !$0.isCompleted }
        for item in notCompletedTasks {
            if !item.isForSchool {
                item.isDoneForToday = true
            }
        }
        try? modelContext.save()
    }
    
    private func clearAllDailyProgress() {
        let notCompletedTasks = items.filter { !$0.isCompleted }
        for item in notCompletedTasks {
            item.isDoneForToday = false
            item.completedTime = 0
        }
        try? modelContext.save()
    }
    
    private func editItem(_ item: Item) {
        // Show edit dialog for macOS
        // This would typically be implemented with a sheet or popover
    }
    
    private func deleteItem(_ item: Item) {
        // Get the temporaryOrder of the item being deleted
        let deletedOrder = item.temporaryOrder
        
        // Save reference to the deleted item for potential undo
        self.lastDeletedItem = item
        
        // Delete the item
        modelContext.delete(item)
        
        // Update the temporaryOrder of all remaining items
        for otherItem in items {
            if otherItem.temporaryOrder > deletedOrder {
                otherItem.temporaryOrder -= 1
            }
        }
        
        // Save the changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save after item deletion: \(error)")
        }
    }
    
    private func undoDelete() {
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
    
    // Data calculation helper methods
    private func getSum() -> Double {
        var sum: Double = 0
        for item in items {
            if item.isDoneForToday! || item.isCompleted {
                continue
            }
            
            let itemDueDate = removeHours(from: item.dueDate)
            
            let days = (Calendar.current.dateComponents([.day], from: removeHours(from: Date()), to: itemDueDate).day ?? 0)
            var doubleDays: Double = 0
            if days > 0 {
                doubleDays = Double(days)
            } else {
                doubleDays = 1 / (Double(abs(days)) + 2)
            }
            
            var value: Double = 1 / doubleDays
            value *= (item.isForSchool ? 1 : 0.1)
            sum += value
        }
        
        return sum
    }
    
    private func removeHours(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func updateToToday(date: Date, important: Bool = false, tomorrow: Bool = false) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let now = Date()
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
        
        // Check if time has already passed today
        let timeHasPassed = components.hour! < currentComponents.hour! ||
                          (components.hour! == currentComponents.hour! &&
                           components.minute! <= currentComponents.minute!)
        
        // Set to tomorrow if explicitly requested or if the time has already passed today
        if tomorrow || (!important && timeHasPassed) {
            return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: now.addingTimeInterval(86400))!
        }
        
        // Otherwise set to today
        return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: now)!
    }
}

// Custom date text view for macOS
struct CustomDateText: View {
    let date: Date
    let isCompleted: Bool
    
    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        Text(dateString(from: date))
            .foregroundStyle(determineColor())
    }
    
    private func dateString(from date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return itemFormatter.string(from: date)
        }
    }
    
    private func determineColor() -> Color {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        if isCompleted {
            return .gray
        } else if date < startOfDay {
            return .red
        } else {
            return .primary
        }
    }
}

// Protocol to allow communication with parent view
protocol ContentViewProtocol {
    func setLastDeletedItem(_ item: Item)
    func allocateTime()
}
