//
//  CustomDatePicker.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2025-04-11.
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
            .font(.caption)
            .foregroundStyle(determineColor())
            .onTapGesture {
                if !isCompleted {
                    self.showingDatePicker = true
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                VStack {
                    DatePicker("Select Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                        .padding()
                    
                    Button("Done") {
                        showingDatePicker = false
                    }
                    .padding()
                }
                .presentationDetents([.medium])
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
