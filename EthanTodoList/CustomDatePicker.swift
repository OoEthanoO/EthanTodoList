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
    @State private var showingDatePicker = false

    var body: some View {
        Text(itemFormatter.string(from: date))
            .onTapGesture {
                self.showingDatePicker = true
            }
            .popover(isPresented: $showingDatePicker) {
                DatePicker("Select Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
                    .padding()
            }
    }
}
