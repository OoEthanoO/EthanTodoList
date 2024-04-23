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
    
    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        List {
            ForEach(items.sorted(by: sortByOrder)){ item in
                VStack(alignment: .leading) {
                    Text("\(item.order): \(item.name)")
                        .font(.headline)
                        .foregroundStyle(item.isForSchool ? Color.red : Color.black)
                    Text("\(itemFormatter.string(from: item.dueDate))")
                        .font(.subheadline)
                }
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
            
            Button("Remove Task") {
                deleteItems(offsets: IndexSet(integer: items.count - 1))
            }
            .padding()
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(order: items.count, name: newTaskTitle, dueDate: newTaskDueDate, isForSchool: newTaskForSchool)
            modelContext.insert(newItem)
            newTaskTitle = ""
            newTaskDueDate = Date()
            newTaskForSchool = true
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
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
