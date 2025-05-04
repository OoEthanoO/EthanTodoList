import SwiftUI
import SwiftData

struct MainView: View {
    @ObservedObject var timerManager: TimerManager
    @Binding var sidebarSelection: Int?
    @State private var isTimerCompletionVisible = false
    @Environment(\.modelContext) private var modelContext
    
    @State private var showAddTask = false
    @State private var showTimeSettings = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $sidebarSelection)
        } detail: {
            ZStack {
                // Main content area
                if let selection = sidebarSelection {
                    switch selection {
                    case 1:
                        TaskListView()
                            .id(selection)
                            .environmentObject(timerManager)
                    case 2:
                        MacTimerView()
                            .id(selection)
                            .environmentObject(timerManager)
                    case 3:
                        TimeSplitsView()
                            .id(selection)
                    case 4:
                        NumberGeneratorView()
                            .id(selection)
                    case 5:
                        DataView()
                            .id(selection)
                    default:
                        Text("Select an item from the sidebar")
                    }
                } else {
                    Text("Select an item from the sidebar")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Timer completion overlay if needed
                if timerManager.showCompletionSheet {
                    MacTimerCompletionView()
                        .environmentObject(timerManager)
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .animation(.easeInOut, value: timerManager.showCompletionSheet)
            .toolbar {
                // Customize toolbar based on selection
                ToolbarItemGroup {
                    if sidebarSelection == 1 {
                        Button(action: {
                            showAddTask = true
                        }) {
                            Label("Add Task", systemImage: "plus")
                        }
                    }
                    
//                    if sidebarSelection == 3 {
//                        Button(action: {
//                            showTimeSettings = true
//                        }) {
//                            Label("Time Settings", systemImage: "gear")
//                        }
//                    }
                    
//                    if sidebarSelection == 5 {
//                        Button(action: {
//                            showSettings = true
//                        }) {
//                            Label("Settings", systemImage: "gear")
//                        }
//                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView()
                    .frame(width: 400, height: 300)
            }
            .sheet(isPresented: $showTimeSettings) {
                TimeSettingsView()
                    .frame(width: 500, height: 400)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .frame(width: 650, height: 700)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NewTask"))) { _ in
            showAddTask = true
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AllocateTime"))) { _ in
            // Find instance of ContentViewProtocol and call allocateTime
            if let contentView = findContentView() {
                contentView.allocateTime()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowTimeSettings"))) { _ in
            showTimeSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowSettings"))) { _ in
            showSettings = true
        }
    }
    
    private func findContentView() -> (any ContentViewProtocol)? {
        if sidebarSelection == 1 {
            // In practice, you would need to have a way to access the TaskListView instance
            // This is a placeholder for that logic
            return nil
        }
        return nil
    }
}
