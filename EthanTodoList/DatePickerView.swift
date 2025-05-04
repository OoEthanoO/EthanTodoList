import SwiftUI

// Custom Date Picker for better macOS layout
struct DatePickerView: View {
    @Binding var selection: Date
    var displayedComponents: DatePickerComponents
    
    var body: some View {
        DatePicker("", selection: $selection, displayedComponents: displayedComponents)
            .datePickerStyle(.stepperField)
            .labelsHidden()
            .frame(width: 180)
    }
}
