import SwiftData
import SwiftUI
import UserNotifications

@main
struct TiempoApp: App {
    @NSApplicationDelegateAdaptor(StatusItemController.self) private var statusItem
    private let container: ModelContainer
    private let notifications = NotificationPresenter()

    init() {
        UNUserNotificationCenter.current().delegate = notifications
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
                .background(HideOnClose())
        }
        .defaultSize(width: 900, height: 600)
        .modelContainer(container)
    }
}
