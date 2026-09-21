import SwiftUI
import SwiftData

@main
struct NowNestApp: App {
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [NowContext.self, ParkedIdea.self], inMemory: isUITesting)
    }
}
