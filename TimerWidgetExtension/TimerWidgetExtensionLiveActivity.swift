import ActivityKit
import WidgetKit
import SwiftUI

struct TimerWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            // Lock screen/banner UI
            HStack(alignment: .center, spacing: 0) {
                // Task name on the left
                VStack(alignment: .leading) {
                    Text(context.state.taskName)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundStyle(.white)
                    
                    if context.state.completedTime > 0 {
                        Text("\(context.state.completedTime)/\(context.state.totalAllocatedTime) min")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
                
                Spacer()
                
                // Timer on the right with larger text
                Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(minWidth: 100, alignment: .trailing)
                    .padding(.trailing, 12)
            }
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: context.state.isRunning ? "timer" : "pause.circle")
                            .foregroundColor(context.state.isRunning ? .green : .orange)
                        
                        // Show remaining time
                        let timeRemaining = context.state.endTime.timeIntervalSince(Date())
                        let hours = Int(timeRemaining) / 3600
                        let minutes = (Int(timeRemaining) % 3600) / 60
                        let seconds = Int(timeRemaining) % 60
                        
                        Text(hours > 0 ?
                             "\(hours)h \(minutes)m \(seconds)s" :
                             "\(minutes)m \(seconds)s")
                            .font(.system(.body, design: .monospaced))
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.completedTime > 0 {
                        Text("\(context.state.completedTime)/\(context.state.totalAllocatedTime)m")
                            .font(.caption)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.taskName)
                        .font(.headline)
                        .lineLimit(1)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Ends at \(formatTime(context.state.endTime))")
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: context.state.isRunning ? "timer" : "pause.circle")
                    .foregroundColor(context.state.isRunning ? .green : .orange)
            } compactTrailing: {
                let timeRemaining = context.state.endTime.timeIntervalSince(Date())
                let hours = Int(timeRemaining) / 3600
                let minutes = (Int(timeRemaining) % 3600) / 60
                let seconds = Int(timeRemaining) % 60
                Text(hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes):\(String(format: "%02d", seconds))")
                    .monospacedDigit()
                    .frame(alignment: .leading)
                    .padding(0)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
