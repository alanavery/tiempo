import Foundation
import SwiftData

@MainActor
@Observable
final class BreakCoordinator {
    let monitor: BreakMonitor
    private var timer: Timer?
    private var context: ModelContext?

    init(monitor: BreakMonitor = BreakMonitor()) {
        self.monitor = monitor
    }

    func start(context: ModelContext) {
        self.context = context
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        guard let context else { return }
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        monitor.tick(tasks: tasks, at: .now, in: context)
    }
}
