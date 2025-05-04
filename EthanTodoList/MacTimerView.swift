import SwiftUI
import SwiftData
import Combine

struct MacTimerView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    // UI state
    @State private var buttonScale: CGFloat = 1.0
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            // Task selection mode
            HStack {
                Text("Task Selection Mode:")
                    .font(.headline)
                
                Picker("", selection: $timerManager.taskSelectionMode) {
                    ForEach(TaskSelectionMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
            .padding()
            
            Text(timerManager.taskSelectionMode == .highestOrder ?
                "Selecting tasks in priority order" :
                "Selecting tasks with highest time allocation")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Task info area
            VStack {
                if let task = timerManager.currentTask {
                    taskInfoView(task: task)
                } else {
                    noTaskSelectedView()
                }
            }
            .frame(height: 180)
            .padding(.bottom, 20)
            
            // Timer display
            ZStack {
                Circle()
                    .stroke(
                        Color.gray.opacity(0.2),
                        lineWidth: 20
                    )
                    .frame(width: 300, height: 300)
                
                if timerManager.isRunning {
                    timerProgressView()
                }
                
                timerDisplayView()
            }
            .frame(height: 320)
            
            // Control buttons
            timerControlButtons()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Component Views
    
    private func taskInfoView(task: Item) -> some View {
        VStack(spacing: 16) {
            Text("Current Task")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text(task.name)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack {
                Text("Progress:")
                    .foregroundColor(.secondary)
                    .font(.title3)
                
                Text("\(task.completedTime ?? 0)/\(task.currentMinutes ?? 0) min")
                    .fontWeight(.medium)
                    .font(.title3)
            }
            .padding(.top, 8)
            
            if timerManager.isRunning {
                Text("Task will complete at \(formatTime(timerManager.endTime!))")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 6)
            }
        }
        .padding()
        .frame(maxWidth: 600)
        .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func noTaskSelectedView() -> some View {
        VStack(spacing: 16) {
            Text("No Active Task")
                .font(.title)
                .fontWeight(.medium)
            
            Text("Press start to begin working on the next task")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: 600)
        .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func timerProgressView() -> some View {
        Circle()
            .trim(from: 0, to: min(1.0, progressFraction))
            .stroke(
                Color.blue,
                style: StrokeStyle(
                    lineWidth: 20,
                    lineCap: .round
                )
            )
            .frame(width: 300, height: 300)
            .rotationEffect(.degrees(-90))
            .animation(.linear, value: progressFraction)
    }
    
    private func timerDisplayView() -> some View {
        VStack {
            if timerManager.isRunning {
                Text(hours > 0 ? "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))" :
                               "\(minutes):\(String(format: "%02d", seconds))")
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .onReceive(timer) { _ in
                        let (hours, minutes, seconds) = timerManager.calculateRemainingTime()
                        self.hours = hours
                        self.minutes = minutes
                        self.seconds = seconds
                    }
                
                Text("Remaining")
                    .font(.title3)
                    .foregroundColor(.secondary)
            } else {
                Text("Ready")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func timerControlButtons() -> some View {
        HStack(spacing: 40) {
            if timerManager.isRunning {
                Button(action: {
                    withAnimation(.spring()) {
                        buttonScale = 0.9
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            buttonScale = 1.0
                            timerManager.stopTimer()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 160, height: 50)
                    .background(Color.red)
                    .cornerRadius(15)
                }
                .buttonStyle(.plain)
                .scaleEffect(buttonScale)
                .keyboardShortcut(.escape, modifiers: [])
                
                Button(action: {
                    withAnimation(.spring()) {
                        buttonScale = 0.9
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            buttonScale = 1.0
                            timerManager.completeTask()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Complete")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 160, height: 50)
                    .background(Color.green)
                    .cornerRadius(15)
                }
                .buttonStyle(.plain)
                .scaleEffect(buttonScale)
                .keyboardShortcut("c", modifiers: [.command])
                
            } else {
                Button(action: {
                    withAnimation(.spring()) {
                        buttonScale = 0.9
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            buttonScale = 1.0
                            timerManager.startTimer()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 160, height: 50)
                    .background(Color.green)
                    .cornerRadius(15)
                }
                .buttonStyle(.plain)
                .scaleEffect(buttonScale)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Helper Properties & Methods
    
    private var progressFraction: CGFloat {
        guard timerManager.isRunning,
              let startTime = timerManager.startTime,
              let endTime = timerManager.endTime else {
            return 0
        }
        
        let totalDuration = endTime.timeIntervalSince(startTime)
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        return CGFloat(elapsedTime / totalDuration)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
