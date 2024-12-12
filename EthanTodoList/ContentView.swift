import SwiftUI
import SwiftData
import Foundation

extension Date: RawRepresentable {
    public var rawValue: String {
        self.timeIntervalSinceReferenceDate.description
    }

    public init?(rawValue: String) {
        self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var items: [Item]
    
    @State private var showingAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate = Date()
    @State private var newTaskForSchool = true
    @State private var showRandomTaskAlert = false
    @State private var showPreviousTaskAlert = false
    @State private var nextTask = ""
    @AppStorage("lastGeneratedTask") var lastGeneratedTask: String = ""
    @AppStorage("lastGeneratedTime") var lastGeneratedTime: Date = Date()
    @AppStorage("homeTime") var homeTime: Date = Date()
    @AppStorage("sleepTime") var sleepTime: Date = Date()
    
    @State var lastDeletedItem: Item?
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    var body: some View {
        Text("\(items.count.description) items")
            .bold()
            .font(.title)
            .padding(.top)
        HStack {
            List {
                ForEach(items.sorted(by: sortByOrder)){ item in
                    ItemView(item: item, dueDate: item.dueDate, contentView: self)
                }
                .onMove(perform: move)
            }
            .frame(maxWidth: .infinity)
            
            VStack {
                Text("Timer Placeholder")
                    .font(.title)
                    .padding()
                Spacer()
            }
            .frame(width: 400)
            .background(Color.gray.opacity(0.1))
        }
        HStack {
            Button(action: {
                self.showingAddTask = true
            }) {
                Text("Add Task")
            }
            .sheet(isPresented: $showingAddTask) {
                VStack {
                    Text("New Task")
                        .font(.title)
                        .bold()
                        .padding()
                    
                    TextField("Task Title", text: $newTaskTitle)
                        .padding()
                    
                    DatePicker("Due Date", selection: $newTaskDueDate, displayedComponents: .date)
                        .padding()
                    
                    Toggle(isOn: $newTaskForSchool) {
                        Text("For school")
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        self.showingAddTask = false
                        addItem()
                    }) {
                        Text("Add Task")
                    }
                }
                .padding()
                .frame(width: 500, height: 400)
            }
            .padding()
            
            Button(action: {
                var sum: Double = 0
                var sortedItems: [Item] {
                    items.sorted(by: sortByOrder)
                }
                for item in sortedItems {
                    if item.isDoneForToday! {
                        continue
                    }
                    
                    let days = (Calendar.current.dateComponents([.day], from: Date(), to: item.dueDate).day ?? 0) + 1
                    var doubleDays: Double = 0
                    if days > 0 {
                        doubleDays = Double(days)
                    } else {
                        doubleDays = 1 / (Double(days) + 2)
                    }
                    let logMessage = "Task \(item.name) is due in \(days) days"
                    LogManager.shared.addLog(logMessage)
                    
                    var value: Double = 1 / doubleDays
                    value *= (item.isForSchool ? 1 : 0.5)
                    
                    let valueLogMessage = "Value: \(value)"
                    LogManager.shared.addLog(valueLogMessage)
                    sum += value
                }
                let sumLogMessage = "Sum: \(sum)"
                LogManager.shared.addLog(sumLogMessage)
                
                let randomValue = Double.random(in: 0...sum)
                let randomValueLogMessage = "Random Value: \(randomValue)"
                LogManager.shared.addLog(randomValueLogMessage)
                
                var currentSum: Double = 0
                for item in sortedItems {
                    if item.isDoneForToday! {
                        continue
                    }
                    
                    let days = (Calendar.current.dateComponents([.day], from: Date(), to: item.dueDate).day ?? 0) + 1
                    var doubleDays: Double = 0
                    if days > 0 {
                        doubleDays = Double(days)
                    } else {
                        doubleDays = 1 / (Double(days) + 2)
                    }
                    let logMessage = "Task \(item.name) is due in \(days) days"
                    LogManager.shared.addLog(logMessage)
                    
                    var fraction: Double = 1 / doubleDays
                    fraction *= (item.isForSchool ? 1 : 0.5)
                    
                    currentSum += fraction
                    
                    if currentSum >= randomValue {
                        print("------------------------------------------")
                        let timeBetweenHomeAndSleep: Int = Calendar.current.dateComponents([.minute], from: homeTime, to: sleepTime).minute ?? 0
                        
                        print("timeBetweenHomeAndSleep = \(timeBetweenHomeAndSleep)")
                        
                        let weekday = Calendar.current.dateComponents([.weekday], from: Date()).weekday!;
                        
                        print("weekday = \(weekday)")
                        
                        var codeMinutes: Int = 0
                        var gameMinutes: Int = 0
                        var codeTime: Date? = sleepTime;
                        var gameTime: Date? = sleepTime;
                        
                        codeMinutes = timeBetweenHomeAndSleep / 8
                        codeTime = Calendar.current.date(byAdding: .minute, value: -(timeBetweenHomeAndSleep / 8), to: sleepTime)
                        
                        if weekday >= 2 && weekday <= 6 {
                            gameMinutes = timeBetweenHomeAndSleep / 16
                        } else {
                            gameMinutes = timeBetweenHomeAndSleep / 8
                        }
                        
                        codeTime = Calendar.current.date(byAdding: .minute, value: -codeMinutes, to: sleepTime)
                        gameTime = Calendar.current.date(byAdding: .minute, value: -gameMinutes, to: sleepTime)
                        
                        print("codeMinutes = \(codeMinutes)")
                        print("codeTime = \(timeFormatter.string(from: codeTime!))")
                        print("gameMinutes = \(gameMinutes)")
                        print("gameTime = \(timeFormatter.string(from: gameTime!))")
                        
                        if Date() >= codeTime! {
                            nextTask = "Go do some coding!" + timeFormatter.string(from: gameTime!)
                            break
                        } else if Date() >= gameTime! {
                            nextTask = "Go do some gaming!"
                            break
                        }
                        
                        let totalWorkMinutes: Int = (Calendar.current.dateComponents([.minute], from: Date(), to: codeTime!).minute ?? 0)
                        
                        print("totalWorkMinutes = \(totalWorkMinutes)")
                        
                        let workMinutes: Int = Int((fraction / sum) * Double(totalWorkMinutes))
                        
                        print("workMinutes = \(workMinutes)")
                        
                        nextTask = item.name + " for \(workMinutes) minutes."
                        lastGeneratedTask = nextTask
                        lastGeneratedTime = Date()
                        
                        break
                    }
                }
                self.showRandomTaskAlert = true
            }) {
                Text("Random Task")
            }
            .alert(isPresented: $showRandomTaskAlert) {
                Alert(title: Text("Next Task"), message: Text(nextTask), dismissButton: .default(Text("Got it!")))
            }
            
            Button(action: {
                self.showPreviousTaskAlert = true
            }) {
                Text("Previous Task")
            }
            .alert(isPresented: $showPreviousTaskAlert) {
                Alert(title: Text("Previous Task"), message: Text(lastGeneratedTask + " at " + timeFormatter.string(from: lastGeneratedTime)), dismissButton: .default(Text("Got it!")))
            }
            
            VStack {
                DatePicker("Home Time", selection: $homeTime, displayedComponents: .hourAndMinute)
                
                DatePicker("Sleep Time", selection: $sleepTime, displayedComponents: .hourAndMinute)
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(order: items.count, name: newTaskTitle, dueDate: newTaskDueDate, isForSchool: newTaskForSchool, isCompleted: false)
            modelContext.insert(newItem)
            newTaskTitle = ""
            newTaskDueDate = Date()
            newTaskForSchool = true
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        withAnimation {
            let sourceIndex = source.first!
            var sourceItem: Item?
            for item in items {
                if item.order == sourceIndex {
                    sourceItem = item
                    break
                }
            }
            if sourceIndex < destination {
                for item in items {
                    if item.order < destination && item.order > sourceIndex {
                        item.order -= 1
                    }
                }
                sourceItem?.order = destination - 1
            } else if sourceIndex > destination {
                for item in items {
                    if item.order >= destination && item.order < sourceIndex {
                        item.order += 1
                    }
                }
                sourceItem?.order = destination
            }
        }
    }
    
    func sortByOrder(item1: Item, item2: Item) -> Bool {
        return item1.order <= item2.order
    }
    
    func undoDelete() {
        if lastDeletedItem != nil {
            modelContext.insert(lastDeletedItem!)
            do {
                try modelContext.save()
            } catch {
                print("Failed to save model context: \(error)")
            }
            for item in items {
                if item.order >= lastDeletedItem!.order {
                    item.order += 1
                }
            }
            lastDeletedItem = nil
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
