import SwiftData
import SwiftUI

@main
struct TiempoApp: App {
    private let container: ModelContainer

    init() {
        let inMemory = ProcessInfo.processInfo.arguments.contains("--uitesting")
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            container = try ModelContainer(
                for: Schema([Project.self, TaskItem.self]),
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 600)
        .modelContainer(container)
    }
}
