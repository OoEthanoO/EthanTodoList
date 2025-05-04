import SwiftUI

struct Sidebar: View {
    @Binding var selection: Int?
    
    var body: some View {
        List(selection: $selection) {
            NavigationLink(value: 1) {
                Label("Tasks", systemImage: "checklist")
            }
            
            NavigationLink(value: 2) {
                Label("Timer", systemImage: "timer")
            }
            
            NavigationLink(value: 3) {
                Label("Time Splits", systemImage: "clock")
            }
            
            NavigationLink(value: 4) {
                Label("Number Generator", systemImage: "dice")
            }
            
            NavigationLink(value: 5) {
                Label("Data", systemImage: "chart.bar.doc.horizontal")
            }
        }
        .navigationTitle("EthanToDo")
        .listStyle(.sidebar)
    }
}
