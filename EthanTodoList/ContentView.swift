//
//  ContentView.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2024-04-22.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var showingAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate = Date()
    @State private var newTaskForSchool = true
    @State private var showAlert = false
    @State private var nextTask = ""

    var body: some View {
        List {
            ForEach(items.sorted(by: sortByOrder)){ item in
                ItemView(item: item, dueDate: item.dueDate)
            }
            .onMove(perform: move)
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
                let furthestDueDate = items.max { $0.dueDate < $1.dueDate }?.dueDate
                var totalDays = 0
                var prefixSums = [(Int, String)]()
                for item in items {
                    if item.isCompleted {
                        continue
                    }
                    let date1 = Calendar.current.startOfDay(for: item.dueDate)
                    let date2 = Calendar.current.startOfDay(for: furthestDueDate!)
                    let diff = Calendar.current.dateComponents([.day], from: date1, to: date2)
                    let days = diff.day! + 1
                    totalDays += item.isForSchool ? days : days / 2
                    prefixSums.append((totalDays, item.name))
                }
                print(prefixSums)
                let randomNumber = Int.random(in: 1...totalDays)
                print(randomNumber)
                if randomNumber <= prefixSums.first!.0 {
                    nextTask = prefixSums.first?.1 ?? ""
                } else {
                    for (index, (sum, _)) in prefixSums.enumerated().reversed() {
                        if randomNumber > sum {
                            if index + 1 < prefixSums.count {
                                nextTask = prefixSums[index + 1].1
                            }
                            break
                        }
                    }
                }
                
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(nextTask, forType: .string)
                showAlert = true
            }) {
                Text("Next Task")
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Next Task"), message: Text(nextTask), dismissButton: .default(Text("Got it!")))
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
                    if item.order >=
                        destination && item.order < sourceIndex {
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
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
