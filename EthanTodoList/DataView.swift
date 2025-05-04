import SwiftUI

struct DataView: View {
    @AppStorage("todayWakeUpTime") var todayWakeUpTime: Date = Date()
    @AppStorage("sleepTime") var sleepTime: Date = Date()
    @AppStorage("wakeUpTime") var wakeUpTime: Date = Date()
    @AppStorage("pomodoroStreak") private var pomodoroStreak: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Title
                Text("Data Dashboard")
                    .font(.largeTitle)
                    .padding(.top)
                
                // Time Settings section
                settingsCard(title: "Time Settings") {
                    VStack(spacing: 0) {
                        settingRow(label: "Today's Wake Up Time") {
                            DatePickerView(selection: $todayWakeUpTime, displayedComponents: .hourAndMinute)
                        }
                        
                        Divider()
                        
                        settingRow(label: "Sleep Time") {
                            DatePickerView(selection: $sleepTime, displayedComponents: .hourAndMinute)
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
                        .padding()
                        
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
                        bulletPoint("Each completed session adds to your streak!")
                        
                        Text("A consistent streak helps build lasting focus habits.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Views
    
    private func settingsCard<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
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
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal)
    }
    
    private func infoCard<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
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
}
