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
    @State var isForSchool: Bool
    
    @Query private var items: [Item]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @FocusState private var isNameFieldFocused: Bool
    
    init(item: Item, dueDate: Date) {
        self.item = item
        self.dueDate = item.dueDate
        self.name = item.name
        self.isCompleted = item.isCompleted
        self.isForSchool = item.isForSchool
    }

    var body: some View {
        HStack {
            if !isEditing {
                Toggle("", isOn: $isCompleted)
                    .onChange(of: isCompleted) {
                        item.isCompleted = isCompleted
                    }
                
                VStack(alignment: .leading) {
                    Text("\(item.name)")
                        .font(.headline)
                        .foregroundStyle(item.isCompleted ? Color.gray : (item.isForSchool ? Color.red : (colorScheme == .dark ? Color.white : Color.black)))
                        .strikethrough(item.isCompleted)
                    
                    CustomDatePicker(date: $dueDate, isCompleted: $isCompleted)
                        .onChange(of: dueDate) {
                            item.dueDate = dueDate
                        }
                }
                
                Spacer()
                
                Button("", systemImage: "pencil.line") {
                    withAnimation {
                        isEditing = true
                        isNameFieldFocused = true
                    }
                }
                
                Button("", systemImage: "trash.fill") {
                    withAnimation {
                        deleteItem(order: item.order)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundStyle(Color.red)
            } else {
                VStack(alignment: .leading) {
                    TextField("Task name", text: $name)
                        .focused($isNameFieldFocused)
                    
                    Toggle(isOn: $isForSchool) {
                        Text("For school")
                    }
                    
                    Button("Save") {
                        isEditing = false
                        item.name = name
                        item.isForSchool = isForSchool
                    }
                }
            }
        }
    }
    
    func deleteItem(order: Int) {
        withAnimation {
            for item in items {
                if item.order == order {
                    ContentView().lastDeletedItem = item
                    modelContext.delete(item)
                    break
                } else if item.order > order {
                    item.order -= 1
                }
            }
        }
    }
}
