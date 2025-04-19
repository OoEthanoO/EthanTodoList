//
//  ItemView.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2025-04-11.
//

import SwiftUI
import SwiftData

struct ItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: Item
    
    @State private var isEditing = false
    @State private var name: String
    @State private var dueDate: Date
    @State private var isForSchool: Bool
    @State private var notes: String
    @State private var isCompleted: Bool
    @FocusState private var isNameFieldFocused: Bool
    
    var items: [Item]
    var contentView: ContentViewProtocol
    
    init(item: Item, items: [Item], contentView: ContentViewProtocol) {
        self.item = item
        self._name = State(initialValue: item.name)
        self._dueDate = State(initialValue: item.dueDate)
        self._isForSchool = State(initialValue: item.isForSchool)
        self._notes = State(initialValue: item.notes ?? "")
        self._isCompleted = State(initialValue: item.isCompleted)
        self.items = items
        self.contentView = contentView
    }
    
    var body: some View {
        HStack(alignment: .top) {
            // Checkboxes aligned to top left
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Toggle("", isOn: $isCompleted)
                        .labelsHidden()
                        .onChange(of: isCompleted) {
                            item.isCompleted = isCompleted
                            item.isDoneForToday = true
                        }
                        .toggleStyle(.checkboxstyle)
                    
                    Toggle("", isOn: $item.isDoneForToday.defaultValue(false))
                        .labelsHidden()
                        .disabled(isCompleted)
                        .toggleStyle(.checkboxstyle)
                }
            }
            .padding(.top, 2)
            
            // Task details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(item.isCompleted ? Color.gray : (item.isForSchool ? Color.red : Color.primary))
                    .strikethrough(isCompleted)
                
                // Date below the name
                CustomDatePicker(date: $dueDate, isCompleted: $isCompleted)
                    .onChange(of: dueDate) {
                        item.dueDate = dueDate
                    }
                
                // Notes below date
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
            }
            
            Spacer()
            
            // Allocated time aligned to top right
            if item.currentMinutes ?? 0 > 0 {
                if let completedTime = item.completedTime, completedTime > 0 {
                    Text("\(completedTime)/\(item.currentMinutes ?? 0) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                } else {
                    Text("\(item.currentMinutes ?? 0) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            isEditing = true
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteItem()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                isEditing = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                Form {
                    TextField("Task name", text: $name)
                        .focused($isNameFieldFocused)
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    
                    TextEditor(text: $notes)
                        .frame(height: 100)
                    
                    Toggle("For school", isOn: $isForSchool)
                }
                .navigationTitle("Edit Task")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isEditing = false
                            // Reset values
                            name = item.name
                            dueDate = item.dueDate
                            isForSchool = item.isForSchool
                            notes = item.notes ?? ""
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            isEditing = false
                            item.name = name
                            item.isForSchool = isForSchool
                            item.notes = notes
                            item.dueDate = dueDate
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    func deleteItem() {
        withAnimation {
            // Get the temporaryOrder of the item being deleted
            let deletedOrder = item.temporaryOrder
            
            // Save reference to the deleted item for potential undo
            contentView.setLastDeletedItem(item)
            
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
    }
}

// Add this extension to simplify handling optional bindings
extension Binding where Value == Bool? {
    func defaultValue(_ defaultValue: Bool) -> Binding<Bool> {
        Binding<Bool>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

// Protocol to allow communication with parent view
protocol ContentViewProtocol {
    func setLastDeletedItem(_ item: Item)
}
