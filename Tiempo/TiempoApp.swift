import SwiftData
import SwiftUI
import UserNotifications

@main
struct TiempoApp: App {
    @NSApplicationDelegateAdaptor(StatusItemController.self) private var statusItem
    private let container: ModelContainer
    private let notifications = NotificationPresenter()
    private let breaks = BreakCoordinator()

    init() {
        UNUserNotificationCenter.current().delegate = notifications
        let inMemory = ProcessInfo.processInfo.arguments.contains("--uitesting")
            || NSClassFromString("XCTestCase") != nil
        let configuration: ModelConfiguration
        do {
            configuration = try Self.storeConfiguration(inMemory: inMemory)
            container = try Self.makeContainer(configuration: configuration)
        } catch {
            guard !inMemory, let configuration = try? Self.storeConfiguration(inMemory: false) else {
                fatalError("Failed to create model container: \(error)")
            }
            Self.quarantineStore(at: configuration.url)
            do {
                container = try Self.makeContainer(configuration: configuration)
            } catch {
                fatalError("Failed to create model container: \(error)")
            }
        }
        container.mainContext.autosaveEnabled = false
        breaks.start(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(breaks)
                .background(HideOnClose())
        }
        .defaultSize(width: 900, height: 600)
        .modelContainer(container)
    }

    private static func storeConfiguration(inMemory: Bool) throws -> ModelConfiguration {
        if inMemory {
            return ModelConfiguration(isStoredInMemoryOnly: true)
        }
        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "com.tiempo.app", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return ModelConfiguration(url: directory.appending(path: "Tiempo.store"))
    }

    private static func makeContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: Schema([Project.self, TaskItem.self]),
            configurations: [configuration]
        )
    }

    private static func quarantineStore(at url: URL) {
        let stamp = Int(Date().timeIntervalSince1970)
        let manager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: url.path + suffix)
            guard manager.fileExists(atPath: source.path) else { continue }
            let destination = URL(fileURLWithPath: url.path + suffix + ".broken-\(stamp)")
            try? manager.moveItem(at: source, to: destination)
        }
    }
}
