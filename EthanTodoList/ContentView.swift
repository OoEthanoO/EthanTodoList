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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var items: [Item]
    @Query private var classes: [Class]
    
    @State private var showingAddTask = false
    @State private var showingViewClasses = false
    @State private var showingAddClass = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate = Date()
    @State private var newTaskForSchool = true
    @State private var newClassStartTime = Date()
    @State private var newClassEndTime = Date()
    @State private var showRandomTaskAlert = false
    @State private var showPreviousTaskAlert = false
    @State private var showSumAlert = false
    @State private var showInfoAlert = false
    @State private var nextTask = ""
    @State private var isCustomGameTime = false
    @State private var customGameTime = 0
    @AppStorage("lastGeneratedTask") var lastGeneratedTask: String = ""
    @AppStorage("homeTime") var homeTime: Date = Date()
    @AppStorage("sleepTime") var sleepTime: Date = Date()
    @AppStorage("wakeUpTime") var wakeUpTime: Date = Date()
    @AppStorage("offset") var offset: Int = 0
    @AppStorage("totalOffset") var totalOffset: Int = 0
    @AppStorage("halfTime") var halfTime: Bool = false
    
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
            TextField("Total Offset", value: $totalOffset, format: .number)
                .frame(width: 50)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Offset", value: $offset, format: .number)
                .frame(width: 50)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            DatePicker("Home Time", selection: $homeTime, displayedComponents: .hourAndMinute)
            
            DatePicker("Sleep Time", selection: $sleepTime, displayedComponents: .hourAndMinute)
            
            Toggle("Half" + (halfTime ? " (" + timeFormatter.string(from: getMiddleTime()) + ")" : ""), isOn: $halfTime)
            
            DatePicker("Wake Up Time", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
            
            Toggle("Custom Game Time", isOn: $isCustomGameTime)
            
            if isCustomGameTime {
                TextField("", value: $customGameTime, format: .number)
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding()
        HStack {
//            Button(action: {
//                self.showingViewClasses = true
//            }) {
//                Text("View Classes")
//            }
//            .sheet(isPresented: $showingViewClasses) {
//                VStack {
//                    Text("Courses")
//                        .font(.title)
//                        .bold()
//                        .padding()
//                    
//                    List(classes) { classItem in
//                        Text("Class from \(timeFormatter.string(from: classItem.startTime)) to \(timeFormatter.string(from: classItem.endTime))")
//                    }
//                    .padding()
//                    
//                    Button(action: {
//                        self.showingAddClass = true
//                    }) {
//                        Image(systemName: "plus")
//                    }
//                    .sheet(isPresented: $showingAddClass) {
//                        VStack {
//                            Text("New Class")
//                                .font(.title)
//                                .bold()
//                                .padding()
//                            
//                            DatePicker("Start Time", selection: $newClassStartTime, displayedComponents: .hourAndMinute)
//                                .padding()
//                            
//                            DatePicker("End Time", selection: $newClassEndTime, displayedComponents: .hourAndMinute)
//                                .padding()
//                            
//                            Spacer()
//                            
//                            Button(action: {
//                                self.showingAddClass = false
//                                addClass()
//                            }) {
//                                Text("Add Class")
//                            }
//                        }
//                    }
//                }
//                .padding()
//                .frame(width: 500, height: 400)
//            }
//            .padding()
            
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
                let sum: Double = getSum()
                
                let randomValue = Double.random(in: 0...sum)
                
                var currentSum: Double = 0
                
                print("------------------------------------------")
                
                let information = getInformation()
                let codeTime = information.1
                let gameTime = information.3
                let curSleepTime = information.4
                
                if Date() >= gameTime {
                    nextTask = "Go do some gaming until " + timeFormatter.string(from: Calendar.current.date(byAdding: .minute, value: -offset, to: curSleepTime)!) + "!"
                    self.showRandomTaskAlert = true
                    return
                } else if Date() >= codeTime {
                    nextTask = "Go do some coding until " + timeFormatter.string(from: gameTime) + "!"
                    self.showRandomTaskAlert = true
                    return
                }
                
                for item in items {
                    
                    if item.isDoneForToday! {
                        continue
                    }
                    
                    item.dueDate = removeHours(from: item.dueDate)
                    if item.isDoneForToday! {
                        continue
                    }
                    
                    let days = (Calendar.current.dateComponents([.day], from: removeHours(from: Date()), to: item.dueDate).day ?? 0)
                    var doubleDays: Double = 0
                    if days > 0 {
                        doubleDays = Double(days)
                    } else {
                        doubleDays = 1 / (Double(days) + 2)
                    }
                    
                    var fraction: Double = 1 / doubleDays
                    fraction *= (item.isForSchool ? 1 : 0.33)
                    
                    currentSum += fraction
                    
                    if currentSum >= randomValue {
                        let totalWorkMinutes: Int = (Calendar.current.dateComponents([.minute], from: Date(), to: codeTime).minute ?? 0)
                        
                        print("totalWorkMinutes = \(totalWorkMinutes)")
                        
                        let workMinutes: Int = Int((fraction / sum) * Double(totalWorkMinutes))
                        
                        print("workMinutes = \(workMinutes)")
                        
                        nextTask = item.name + " for \(workMinutes) minutes\nWork until \(timeFormatter.string(from: codeTime))"
                        lastGeneratedTask = nextTask
                        
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
            .padding()
            
            Button(action: {
                self.showPreviousTaskAlert = true
            }) {
                Text("Previous Task")
            }
            .alert(isPresented: $showPreviousTaskAlert) {
                Alert(title: Text("Previous Task"), message: Text(lastGeneratedTask), dismissButton: .default(Text("Got it!")))
            }
            .padding()
            
            Button(action: {
                self.showSumAlert = true
            }) {
                Text("Show Sum")
            }
            .alert(isPresented: $showSumAlert) {
                Alert(title: Text("Sum"), message: Text("\(getSum())"))
            }
            .padding()
            
            Button(action: {
                self.showInfoAlert = true
            }) {
                Text("Show Info")
            }
            .alert(isPresented: $showInfoAlert) {
                let information = getInformation()
                let codeMinutes = information.0
                let codeTime = information.1
                let gameMinutes = information.2
                let gameTime = information.3
                return Alert(title: Text("Information"), message: Text("Code Minutes: \(codeMinutes)\nCode Time: \(timeFormatter.string(from: codeTime))\nGame Minutes: \(gameMinutes)\nGame Time: \(timeFormatter.string(from: gameTime))"))
            }
            .padding()
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
    
    private func addClass() {
        withAnimation {
            let newClass = Class(name: "", startTime: newClassStartTime, endTime: newClassEndTime)
            modelContext.insert(newClass)
            newClassStartTime = Date()
            newClassEndTime = Date()
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
    
    private func updateToToday(date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: Date())!
    }
    
    private func getSum() -> Double {
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
            value *= (item.isForSchool ? 1 : 0.33)
            sum += value
        }
        
        return sum
    }
    
    private func getMiddleTime() -> Date {
        let timeBetweenHomeAndSleep: Int = (Calendar.current.dateComponents([.minute], from: removeSeconds(from: homeTime), to: removeSeconds(from: sleepTime)).minute ?? 0)
        
        var middleTime = Calendar.current.date(byAdding: .minute, value: -(timeBetweenHomeAndSleep / 2), to: sleepTime)
        middleTime = updateToToday(date: middleTime!)
        
        return middleTime!
    }
    
    private func getInformation() -> (Int, Date, Int, Date, Date) {
        homeTime = updateToToday(date: homeTime)
        sleepTime = updateToToday(date: sleepTime)
        
        var curHomeTime: Date = homeTime
        var curSleepTime: Date = sleepTime
        
        if halfTime {
            let middleTime = getMiddleTime()
            print("middleTime = \(timeFormatter.string(from: middleTime))")
            if Calendar.current.dateComponents([.minute], from: removeSeconds(from: Date()), to: removeSeconds(from: middleTime)).minute! < 0 {
                curHomeTime = middleTime
            } else {
                curSleepTime = middleTime
            }
        }
        
        let timeBetweenHomeAndSleep = (Calendar.current.dateComponents([.minute], from: removeSeconds(from: curHomeTime), to: removeSeconds(from: curSleepTime)).minute ?? 0) - totalOffset
        
        print("timeBetweenHomeAndSleep = \(timeBetweenHomeAndSleep)")
        
        let weekday = Calendar.current.dateComponents([.weekday], from: Date()).weekday!;
        
        print("weekday = \(weekday)")
        
        var codeMinutes: Int = 0
        var gameMinutes: Int = 0
        var codeTime: Date? = curSleepTime;
        var gameTime: Date? = curSleepTime;
        
        codeMinutes = timeBetweenHomeAndSleep / 8
        
        if isCustomGameTime {
            gameMinutes = customGameTime
        } else {
            if weekday >= 2 && weekday <= 5 {
                gameMinutes = timeBetweenHomeAndSleep / 8
            } else {
                gameMinutes = timeBetweenHomeAndSleep / 2
            }
        }
        
        gameTime = Calendar.current.date(byAdding: .minute, value: -(gameMinutes + offset), to: curSleepTime)
        codeTime = Calendar.current.date(byAdding: .minute, value: -codeMinutes, to: gameTime!)
        gameTime = removeSeconds(from: gameTime!)
        codeTime = removeSeconds(from: codeTime!)
        
        print("codeMinutes = \(codeMinutes)")
        print("codeTime = \(timeFormatter.string(from: codeTime!))")
        print("gameMinutes = \(gameMinutes)")
        print("gameTime = \(timeFormatter.string(from: gameTime!))")
        
        return (codeMinutes, codeTime!, gameMinutes, gameTime!, curSleepTime)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
