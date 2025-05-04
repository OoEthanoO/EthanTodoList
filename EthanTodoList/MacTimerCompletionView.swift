import SwiftUI

struct MacTimerCompletionView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.green)
                
                Text("Task Complete!")
                    .font(.system(size: 32, weight: .bold))
                
                if let task = timerManager.currentTask {
                    Text(task.name)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    withAnimation {
                        timerManager.showCompletionSheet = false
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .padding()
                        .frame(width: 200)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(50)
            .background(colorScheme == .dark ?
                      Color(NSColor.windowBackgroundColor).opacity(0.95) :
                      Color.white.opacity(0.95))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(50)
            .frame(width: 500, height: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
        .edgesIgnoringSafeArea(.all)
    }
}
