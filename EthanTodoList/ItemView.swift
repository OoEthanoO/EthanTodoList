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
    
    @Query private var items: [Item]
    
    @Environment(\.modelContext) private var modelContext
    
    @FocusState private var isNameFieldFocused: Bool
    
    init(item: Item, dueDate: Date) {
        self.item = item
        self.dueDate = item.dueDate
        self.name = item.name
    }

    var body: some View {
        HStack {
            if !isEditing {
                VStack(alignment: .leading) {
                    Text("\(item.order): \(item.name)")
                        .font(.headline)
                        .foregroundStyle(item.isForSchool ? Color.red : Color.black)
                    
                    CustomDatePicker(date: $dueDate)
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
                .backgroundStyle(Color.red)
            } else {
                VStack(alignment: .leading) {
                    TextField("Task name", text: $name)
                        .focused($isNameFieldFocused)
                    
                    Button("Save") {
                        isEditing = false
                        item.name = name
                    }
                }
            }
        }
    }
    
    func deleteItem(order: Int) {
        withAnimation {
            for item in items {
                if item.order == order {
                    modelContext.delete(item)
                } else if item.order > order {
                    item.order -= 1
                }
            }
        }
    }
}
