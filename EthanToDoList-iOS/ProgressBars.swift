import SwiftUI

struct TimelineMarker: Identifiable {
    let id = UUID()
    let time: Date
    let label: String
    let color: Color
    let icon: String?
}

struct EnhancedTimelineBar: View {
    let startTime: Date
    let endTime: Date
    let markers: [TimelineMarker]
    let useEquidistantMarkers: Bool = true // Set to true to use equidistant spacing
    
    @Environment(\.colorScheme) var colorScheme
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    // Calculate position for a marker based on its time
    private func position(for markerTime: Date) -> CGFloat {
        let totalDuration = endTime.timeIntervalSince(startTime)
        let markerOffset = markerTime.timeIntervalSince(startTime)
        
        // Clamp to 0-1 range
        return max(0, min(1, totalDuration > 0 ? markerOffset / totalDuration : 0))
    }
    
    // Calculate progress for current time
    private var progress: CGFloat {
        let totalDuration = endTime.timeIntervalSince(startTime)
        let elapsedTime = currentTime.timeIntervalSince(startTime)
        
        return max(0, min(1, totalDuration > 0 ? CGFloat(elapsedTime / totalDuration) : 0))
    }
    
    // Calculate equidistant position based on index
    private func equidistantPosition(forIndex index: Int, totalCount: Int) -> CGFloat {
        if totalCount <= 1 {
            return 0.5 // Center if only one marker
        }
        
        // Distribute evenly, with first at 0.0 and last at 1.0
        print("\(index): \(CGFloat(index) / CGFloat(totalCount - 1))")
        return CGFloat(index) / CGFloat(totalCount - 1)
    }
    
    // Start the timer to update current time
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            withAnimation(.linear(duration: 0.5)) {
                currentTime = Date()
            }
        }
    }
    
    // Stop the timer when view disappears
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Timeline bar with markers
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar - make it slightly less wide to accommodate edge markers
                    // Add horizontal padding to allow markers to be centered at the edges
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width - 16, height: 6)
                        .position(x: geometry.size.width / 2, y: 45)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: (geometry.size.width - 16) * progress, height: 6)
                        .position(x: 8 + (geometry.size.width - 16) * progress / 2, y: 45)
                    
                    // Current time marker
                    if progress > 0 && progress < 1 {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .overlay(
                                Circle()
                                    .stroke(Color.purple, lineWidth: 2)
                            )
                            .position(x: 8 + (geometry.size.width - 16) * progress, y: 45)
                    }
                    
                    // Markers
                    ForEach(Array(markers.enumerated()), id: \.element.id) { index, marker in
                        let position = useEquidistantMarkers
                            ? equidistantPosition(forIndex: index, totalCount: markers.count)
                            : position(for: marker.time)
                        
                        MarkerView(
                            marker: marker,
                            position: position,
                            totalWidth: geometry.size.width,
                            isFirstMarker: index == 0,
                            isLastMarker: index == markers.count - 1
                        )
                    }
                }
            }
            .frame(height: 90) // Adjust based on your needs
            
            // Time labels at bottom
            HStack {
                Text(timeFormatter.string(from: startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if progress > 0 && progress < 1 {
                    Text(timeFormatter.string(from: currentTime))
                        .font(.caption)
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Text(timeFormatter.string(from: endTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            currentTime = Date()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
}

struct MarkerView: View {
    let marker: TimelineMarker
    let position: CGFloat
    let totalWidth: CGFloat
    let isFirstMarker: Bool
    let isLastMarker: Bool
    
    // Constants for layout calculations
    private let markerWidth: CGFloat = 60
    private let markerVerticalPosition: CGFloat = 45
    
    var body: some View {
        VStack(spacing: 4) {
            // Icon or circle
            Group {
                if let iconName = marker.icon {
                    Image(systemName: iconName)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(marker.color)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(marker.color)
                        .frame(width: 14, height: 14)
                }
            }
            .background(
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 32, height: 32)
            )
            
            // Line from marker to timeline
            Rectangle()
                .fill(marker.color.opacity(0.6))
                .frame(width: 1, height: 8)
            
            // Label text
            Text(marker.label)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .fixedSize()
                .foregroundColor(marker.color)
            
            // Time display
            Text(timeFormatter.string(from: marker.time))
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize()
        }
        .frame(width: markerWidth)
        .position(x: calculateXPosition(), y: markerVerticalPosition)
    }
    
    // Calculate x position with improved edge handling
    private func calculateXPosition() -> CGFloat {
        if isFirstMarker {
            // Position first marker precisely at the left edge with proper centering
            return totalWidth * position + 8
        } else if isLastMarker {
            // Position last marker precisely at the right edge with proper centering
            return totalWidth * position - 8
        } else {
            // For middle markers, calculate position based on percentage
            return totalWidth * position
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
