import SwiftUI  // ✅ Required

struct ContentView: View {
    var body: some View {
        TabView {
            GradesView()  // ✅ Must be a View
                .tabItem {
                    Label("Grades", systemImage: "chart.bar")
                }
            
            SettingsView()  // ✅ Must also be a View
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
