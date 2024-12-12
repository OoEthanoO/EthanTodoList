//
//  CustomDatePicker.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2024-04-25.
//

import SwiftUI

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()

struct CustomDatePicker: View {
    @Binding var date: Date
    @Binding var isCompleted: Bool
    
    @State private var showingDatePicker = false
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text(dateString(from: date))
            .foregroundStyle(determineColor())
            .onTapGesture {
                if !isCompleted {
                    self.showingDatePicker = true
                }
            }
            .popover(isPresented: $showingDatePicker) {
                DatePicker("Select Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
                    .padding()
            }
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
            return colorScheme == .dark ? .white : .black
        }
    }
}
