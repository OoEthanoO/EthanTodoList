//
//  ItemView.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2024-04-25.
//

import SwiftUI
import SwiftData

struct ItemView: View {
    
    var item: Item
    
    @State var dueDate: Date
    @State var name: String
    @State var isEditing = false
    @State var isCompleted: Bool
    @State var isDoneForToday: Bool
    @State var isForSchool: Bool
    @State var contentView: ContentView
    @State var order: Int
    @State private var isHovering = false
    @State private var notes: String
    
    @Query private var items: [Item]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isNotesFieldFocused: Bool
    
    init(item: Item, dueDate: Date, contentView: ContentView) {
        self.item = item
        self.dueDate = item.dueDate
        self.name = item.name
        self.isCompleted = item.isCompleted
        self.isForSchool = item.isForSchool
        self.contentView = contentView
        self.order = item.order
        self.notes = item.notes ?? ""
        self.isDoneForToday = item.isDoneForToday ?? false
    }

    var body: some View {
        HStack {
            if !isEditing {
                Toggle("", isOn: $isCompleted)
                    .onChange(of: isCompleted) {
                        item.isCompleted = isCompleted
                        isDoneForToday = true
                        item.isDoneForToday = isDoneForToday
                    }
                
                Toggle("", isOn: $isDoneForToday)
                    .onChange(of: isDoneForToday) {
                        item.isDoneForToday = isDoneForToday
                    }
                    .disabled(isCompleted)
                
                VStack(alignment: .leading) {
                    Text("\(item.order): \(item.name)")
                        .font(.headline)
                        .foregroundStyle(item.isCompleted ? Color.gray : (item.isForSchool ? Color.red : (colorScheme == .dark ? Color.white : Color.black)))
                        .strikethrough(item.isCompleted)
                    
                    CustomDatePicker(date: $dueDate, isCompleted: $isCompleted)
                        .onChange(of: dueDate) {
                            item.dueDate = dueDate
                        }
                    
                    if item.notes != "" {
                        Text("\(item.notes ?? "")")
                            .foregroundStyle(Color.gray)
                    }
                }
                
                Spacer()
                
                Text("\(item.currentMinutes ?? 0)")
                
                if isHovering {
                    
                    Button("", systemImage: "pencil.line") {
                        withAnimation {
                            isEditing = true
                            isNameFieldFocused = true
                            order = item.order
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button("", systemImage: "trash.fill") {
                        withAnimation {
                            deleteItem(order: item.order)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundStyle(Color.red)
                }
            } else {
                VStack(alignment: .leading) {
                    TextField("Task name", text: $name)
                        .focused($isNameFieldFocused)
                
                    TextEditor(text: $notes)
                    
                    Stepper("Order: \(order)", value: $order)
                    
                    Toggle(isOn: $isForSchool) {
                        Text("For school")
                    }
                    
                    Button("Save") {
                        isEditing = false
                        item.name = name
                        item.isForSchool = isForSchool
                        item.order = order
                        item.notes = notes
                    }
                }
            }
        }
        .onHover { hovering in
            withAnimation {
                self.isHovering = hovering
            }
        }
    }
    
    func deleteItem(order: Int) {
        withAnimation {
            for item in items {
                if item.order == order {
                    contentView.lastDeletedItem = item
                    modelContext.delete(item)
                } else if item.order > order {
                    item.order -= 1
                }
            }
        }
    }
}
