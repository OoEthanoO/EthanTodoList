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
        Text(itemFormatter.string(from: date))
            .foregroundStyle(isCompleted ? .gray : (colorScheme == .dark ? .white : .black))
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
}
