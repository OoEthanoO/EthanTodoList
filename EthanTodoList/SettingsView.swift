import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("totalOffset") var totalOffset: Int = 0
    @AppStorage("offset") var offset: Int = 0
    @AppStorage("homeTime") var homeTime: Date = Date()
    @AppStorage("sleepTime") var sleepTime: Date = Date()
    @AppStorage("sleepTomorrow") var sleepTomorrow: Bool = false
    @AppStorage("halfTime") var halfTime: Bool = false
    @AppStorage("wakeUpTime") var wakeUpTime: Date = Date()
    @AppStorage("todayWakeUpTime") var todayWakeUpTime: Date = Date()
    @AppStorage("pomodoroStreak") var pomodoroStreak: Int = 0
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Time Settings Section
                settingsCard(title: "Time Settings") {
                    VStack(spacing: 0) {
                        settingRow(label: "Total Offset") {
                            HStack {
                                Button(action: { totalOffset = max(0, totalOffset - 10) }) {
                                    Image(systemName: "minus")
                                }
                                .buttonStyle(.plain)
                                
                                TextField("", value: $totalOffset, formatter: NumberFormatter())
                                    .frame(width: 60)
                                
                                Button(action: { totalOffset = min(1440, totalOffset + 10) }) {
                                    Image(systemName: "plus")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Divider()
                        
                        settingRow(label: "Offset") {
                            HStack {
                                Button(action: { offset = max(0, offset - 10) }) {
                                    Image(systemName: "minus")
                                }
                                .buttonStyle(.plain)
                                
                                TextField("", value: $offset, formatter: NumberFormatter())
                                    .frame(width: 60)
                                
                                Button(action: { offset = min(1440, offset + 10) }) {
                                    Image(systemName: "plus")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Schedule Times Section
                settingsCard(title: "Schedule Times") {
                    VStack(spacing: 0) {
                        settingRow(label: "Today's Wake Up Time") {
                            DatePickerView(selection: $todayWakeUpTime, displayedComponents: .hourAndMinute)
                        }
                        
                        Divider()
                        
                        settingRow(label: "Home Time") {
                            DatePickerView(selection: $homeTime, displayedComponents: .hourAndMinute)
                        }
                        
                        Divider()
                        
                        settingRow(label: "Sleep Time") {
                            DatePickerView(selection: $sleepTime, displayedComponents: .hourAndMinute)
                        }
                        
                        Divider()
                        
                        settingRow(label: "Sleep Tomorrow") {
                            Toggle("", isOn: $sleepTomorrow)
                                .labelsHidden()
                        }
                        
                        Divider()
                        
                        settingRow(label: "Half Time") {
                            Toggle("", isOn: $halfTime)
                                .labelsHidden()
                        }
                        
                        if halfTime {
                            Divider()
                            
                            settingRow(label: "Half Time Value") {
                                Text(timeFormatter.string(from: getMiddleTime()))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        settingRow(label: "Tomorrow Wake Up Time") {
                            DatePickerView(selection: $wakeUpTime, displayedComponents: .hourAndMinute)
                        }
                    }
                }
                
                // Pomodoro Streak section
                settingsCard(title: "Pomodoro Streak") {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .resizable()
                                .frame(width: 20, height: 25)
                                .foregroundStyle(.orange)
                            
                            Text("Current Streak")
                                .font(.headline)
                            
                            Spacer()
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    if pomodoroStreak > 0 {
                                        withAnimation {
                                            pomodoroStreak -= 1
                                        }
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                
                                Text("\(pomodoroStreak)")
                                    .font(.system(size: 36, weight: .bold))
                                    .frame(minWidth: 60)
                                    .foregroundColor(.orange)
                                
                                Button(action: {
                                    withAnimation {
                                        pomodoroStreak += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Divider()
                        
                        Button("Reset Streak") {
                            withAnimation {
                                pomodoroStreak = 0
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.red)
                    }
                }
                
                // Pomodoro Technique Info
                infoCard(title: "Pomodoro Technique") {
                    VStack(alignment: .leading, spacing: 12) {
                        bulletPoint("Work for 25 minutes")
                        bulletPoint("Take a 5 minute break")
                        bulletPoint("After 4 sessions, take a longer 15-30 minute break")
                        bulletPoint("Each completed session adds to your streak")
                    }
                }
            }
            .padding()
        }
    }
    
    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            content()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
    
    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func settingRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            content()
        }
        .padding()
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .fontWeight(.bold)
            
            Text(text)
        }
    }
    
    private func getMiddleTime() -> Date {
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
        
        return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: now)!
    }
}
