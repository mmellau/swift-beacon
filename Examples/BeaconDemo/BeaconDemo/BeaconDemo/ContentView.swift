import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Tasks", systemImage: "checklist") {
                TasksView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
