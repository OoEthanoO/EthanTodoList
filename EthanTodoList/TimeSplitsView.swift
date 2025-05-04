import SwiftUI

struct TimeSplitsView: View {
    @AppStorage("todayWakeUpTime") var todayWakeUpTime: Date = Date()
    @AppStorage("sleepTime") var sleepTime: Date = Date()
    @AppStorage("wakeUpTime") var wakeUpTime: Date = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Title and settings button
                HStack {
                    Text("Time Splits Calculator")
                        .font(.title)
                    
                    Spacer()
                    
//                    Button(action: {
//                        NotificationCenter.default.post(name: Notification.Name("ShowTimeSettings"), object: nil)
//                    }) {
//                        Label("Settings", systemImage: "gear")
//                            .padding()
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Wake up to Wake up section
                timeSection(
                    title: "Wake Up to Wake Up",
                    content: wakeUpToWakeUpContent,
                    accentColor: .purple
                )
                
                // Wake up to Sleep section
                timeSection(
                    title: "Wake Up to Sleep",
                    content: wakeUpToSleepContent,
                    accentColor: .blue
                )
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Section Content Builders
    
    private func wakeUpToWakeUpContent() -> some View {
        VStack(spacing: 0) {
            timeRow(
                icon: "sunrise",
                iconColor: .orange,
                label: "Today",
                time: formatTime(todayWakeUpTime)
            )
            
            Divider()
            
            timeRow(
                icon: "arrow.up.and.down",
                iconColor: .purple,
                label: "Half Time",
                time: formatTime(calculateMidPoint(todayWakeUpTime, wakeUpTime)),
                isHighlighted: true,
                highlightColor: .purple
            )
            
            Divider()
            
            timeRow(
                icon: "sunrise",
                iconColor: .orange,
                label: "Tomorrow",
                time: formatTime(wakeUpTime)
            )
        }
    }
    
    private func wakeUpToSleepContent() -> some View {
        let adjustedSleepTime = getAdjustedSleepTime(from: wakeUpTime)
        let doubleSplits = calculateDoubleSplit(todayWakeUpTime, adjustedSleepTime)
        let tripleSplits = calculateTripleSplit(todayWakeUpTime, adjustedSleepTime)
        
        return VStack(spacing: 0) {
            timeRow(
                icon: "sunrise",
                iconColor: .orange,
                label: "Wake Up",
                time: formatTime(todayWakeUpTime)
            )
            
            Divider()
            
            VStack(spacing: 10) {
                timeRow(
                    icon: "2.circle.fill",
                    iconColor: .green,
                    label: "Double Split",
                    time: formatTime(doubleSplits.0),
                    isHighlighted: true,
                    highlightColor: .green
                )
                
                timeRow(
                    icon: "",
                    iconColor: .clear,
                    label: "",
                    time: formatTime(doubleSplits.1),
                    isHighlighted: true,
                    highlightColor: .green
                )
            }
            .padding(.vertical, 5)
            
            Divider()
            
            VStack(spacing: 10) {
                timeRow(
                    icon: "3.circle.fill",
                    iconColor: .red,
                    label: "Triple Split",
                    time: formatTime(tripleSplits.0),
                    isHighlighted: true,
                    highlightColor: .red
                )
                
                timeRow(
                    icon: "",
                    iconColor: .clear,
                    label: "",
                    time: formatTime(tripleSplits.1),
                    isHighlighted: true,
                    highlightColor: .red
                )
                
                timeRow(
                    icon: "",
                    iconColor: .clear,
                    label: "",
                    time: formatTime(tripleSplits.2),
                    isHighlighted: true,
                    highlightColor: .red
                )
            }
            .padding(.vertical, 5)
            
            Divider()
            
            timeRow(
                icon: "moon.fill",
                iconColor: .indigo,
                label: "Sleep",
                time: formatTime(sleepTime),
                addInfo: isSleepNextDay() ? "(next day)" : nil
            )
        }
    }
    
    // MARK: - Helper Views
    
    private func timeSection(title: String, content: @escaping () -> some View, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            content()
                .background(Color(.windowBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal)
    }
    
    private func timeRow(
        icon: String,
        iconColor: Color,
        label: String,
        time: String,
        isHighlighted: Bool = false,
        highlightColor: Color = .primary,
        addInfo: String? = nil
    ) -> some View {
        HStack {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 30)
            } else {
                Spacer()
                    .frame(width: 30)
            }
            
            if !label.isEmpty {
                Text(label)
                    .foregroundColor(.secondary)
                    .frame(width: 120, alignment: .leading)
            } else {
                Spacer()
                    .frame(width: 120)
            }
            
            Spacer()
            
            Text(time)
                .font(.system(.body, design: .monospaced))
                .bold(isHighlighted)
                .foregroundColor(isHighlighted ? highlightColor : .primary)
            
            if let additionalInfo = addInfo {
                Text(additionalInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func isSleepNextDay() -> Bool {
        let calendar = Calendar.current
        return calendar.dateComponents([.hour, .minute], from: todayWakeUpTime).hour! >
               calendar.dateComponents([.hour, .minute], from: sleepTime).hour!
    }
    
    private func updateToToday(date: Date, important: Bool = false, tomorrow: Bool = false) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let now = Date()
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
        
        // Check if time has already passed today
        let timeHasPassed = components.hour! < currentComponents.hour! ||
                          (components.hour! == currentComponents.hour! &&
                           components.minute! <= currentComponents.minute!)
        
        // Set to tomorrow if explicitly requested or if the time has already passed today
        if tomorrow || (!important && timeHasPassed) {
            return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: now.addingTimeInterval(86400))!
        }
        
        // Otherwise set to today
        return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: now)!
    }
    
    private func calculateMidPoint(_ startDate: Date, _ endDate: Date) -> Date {
        let todayStartDate = updateToToday(date: startDate, important: true)
        let tomorrowEndDate = updateToToday(date: endDate, tomorrow: true)
        let timeInterval = tomorrowEndDate.timeIntervalSince(todayStartDate) / 2.0
        return todayStartDate.addingTimeInterval(timeInterval)
    }
    
    private func getAdjustedSleepTime(from wakeUpTime: Date) -> Date {
        // Extract hour and minute components
        let calendar = Calendar.current
        let sleepComponents = calendar.dateComponents([.hour, .minute], from: sleepTime)
        let wakeUpComponents = calendar.dateComponents([.hour, .minute], from: wakeUpTime)
        
        // Create base date with today's date
        var sleepTimeDate = calendar.startOfDay(for: Date())
        
        // Set the hour and minute from sleepTime
        sleepTimeDate = calendar.date(bySettingHour: sleepComponents.hour!, minute: sleepComponents.minute!, second: 0, of: sleepTimeDate)!
        
        if sleepComponents.hour! <= wakeUpComponents.hour! {
            sleepTimeDate = calendar.date(byAdding: .day, value: 1, to: sleepTimeDate)!
        }
        
        return sleepTimeDate
    }
    
    private func calculateDoubleSplit(_ startDate: Date, _ endDate: Date) -> (Date, Date) {
        let todayStartDate = updateToToday(date: startDate, important: true)
        let totalInterval = endDate.timeIntervalSince(todayStartDate)
        let firstSplit = todayStartDate.addingTimeInterval(totalInterval / 3.0)
        let secondSplit = todayStartDate.addingTimeInterval(2 * totalInterval / 3.0)
        return (firstSplit, secondSplit)
    }
    
    private func calculateTripleSplit(_ startDate: Date, _ endDate: Date) -> (Date, Date, Date) {
        let todayStartDate = updateToToday(date: startDate, important: true)
        let totalInterval = endDate.timeIntervalSince(todayStartDate)
        let firstSplit = todayStartDate.addingTimeInterval(totalInterval / 4.0)
        let secondSplit = todayStartDate.addingTimeInterval(2 * totalInterval / 4.0)
        let thirdSplit = todayStartDate.addingTimeInterval(3 * totalInterval / 4.0)
        return (firstSplit, secondSplit, thirdSplit)
    }
}
