import SwiftUI

struct TimeSettingsView: View {
    @AppStorage("totalOffset") var totalOffset: Int = 0
    @AppStorage("offset") var offset: Int = 0
    @AppStorage("homeTime") var homeTime: Date = Date()
    @AppStorage("sleepTime") var sleepTime: Date = Date()
    @AppStorage("sleepTomorrow") var sleepTomorrow: Bool = false
    @AppStorage("halfTime") var halfTime: Bool = false
    @AppStorage("wakeUpTime") var wakeUpTime: Date = Date()
    
    @Environment(\.dismiss) private var dismiss
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Time Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Form {
                Section("Time Offsets") {
                    HStack {
                        Text("Total Offset")
                        Spacer()
                        TextField("", value: $totalOffset, formatter: NumberFormatter())
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Offset")
                        Spacer()
                        TextField("", value: $offset, formatter: NumberFormatter())
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Schedule Times") {
                    DatePicker("Home Time", selection: $homeTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("Sleep Time", selection: $sleepTime, displayedComponents: .hourAndMinute)
                    
                    Toggle("Sleep Tomorrow", isOn: $sleepTomorrow)
                    
                    Toggle("Half Time", isOn: $halfTime)
                    
                    if halfTime {
                        Text("Half time: \(timeFormatter.string(from: getMiddleTime()))")
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker("Wake Up Time", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
                }
            }
            .formStyle(.grouped)
            
            Button("Done") {
                dismiss()
            }
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding()
    }
    
    private func getMiddleTime() -> Date {
        // Implementation from iOS app
        let timeBetweenHomeAndSleep: Int = (Calendar.current.dateComponents([.minute], from: removeSeconds(from: homeTime), to: removeSeconds(from: sleepTime)).minute ?? 0)
        
        var middleTime = Calendar.current.date(byAdding: .minute, value: -(timeBetweenHomeAndSleep / 2), to: sleepTime)
        middleTime = updateToToday(date: middleTime!)
        
        return middleTime!
    }
    
    private func removeSeconds(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func updateToToday(date: Date, important: Bool = false) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let now = Date()
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
        
        // Check if time has already passed today
        let timeHasPassed = components.hour! < currentComponents.hour! ||
                          (components.hour! == currentComponents.hour! &&
                           components.minute! <= currentComponents.minute!)
        
        // Set to tomorrow if the time has already passed today
        if !important && timeHasPassed {
            return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: now.addingTimeInterval(86400))!
        }
        
        // Otherwise set to today
        return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: now)!
    }
}
