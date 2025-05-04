import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var items: [Item]
    
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate = Date()
    @State private var newTaskForSchool = true
    @State private var notes = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Task")
                .font(.title2)
                .fontWeight(.semibold)
            
            Form {
                TextField("Task Title", text: $newTaskTitle)
                
                DatePicker("Due Date", selection: $newTaskDueDate, displayedComponents: .date)
                
                Toggle("For School", isOn: $newTaskForSchool)
                
                TextField("Notes", text: $notes)
                    .frame(height: 60)
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Add Task") {
                    if !newTaskTitle.isEmpty {
                        addItem()
                        dismiss()
                    }
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(newTaskTitle.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding()
    }
    
    private func addItem() {
        // Create the new item
        let newItem = Item(name: newTaskTitle, dueDate: newTaskDueDate,
                         isForSchool: newTaskForSchool, isCompleted: false)
        newItem.notes = notes
        
        // Find the position where the new item should be inserted based on due date
        var insertPosition = items.count // Default to end
        
        // Get items sorted by their current temporary order
        let orderedItems = items.sorted(by: { $0.temporaryOrder < $1.temporaryOrder })
        
        for (index, item) in orderedItems.enumerated() {
            if removeHours(from: newTaskDueDate) < removeHours(from: item.dueDate) {
                // Found a task with a later due date, insert before this one
                insertPosition = index
                break
            }
        }
        
        // Shift temporaryOrder of all items at or after the insertion position
        for item in items {
            if item.temporaryOrder >= insertPosition {
                item.temporaryOrder += 1
            }
        }
        
        // Set the new item's temporaryOrder to the insertion position
        newItem.temporaryOrder = insertPosition
        
        // Insert the new item
        modelContext.insert(newItem)
        
        // Save changes to ensure consistent state
        do {
            try modelContext.save()
        } catch {
            print("Failed to save model context after adding item: \(error)")
        }
    }
    
    private func removeHours(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }
}
