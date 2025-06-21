import SwiftUI

@main
struct GradebookApp: App {
    @StateObject private var studentManager = StudentManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(studentManager)
        }
    }
}
