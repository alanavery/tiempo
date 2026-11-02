import Foundation
import SwiftData

@MainActor
@Observable
final class BreakCoordinator {
    let monitor: BreakMonitor
    let meetings: MeetingSync
    var onTotalElapsed: ((TimeInterval) -> Void)?
    private var timer: Timer?
    private var context: ModelContext?

    init(monitor: BreakMonitor = BreakMonitor(), meetings: MeetingSync = MeetingSync()) {
        self.monitor = monitor
        self.meetings = meetings
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

    func reportTotal() {
        publishTotal(at: .now)
    }

    private func tick() {
        guard let context else { return }
        var tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        publishTotal(tasks: tasks, at: .now)
        meetings.tick(
            tasks: tasks,
            at: .now,
            in: context,
            endingBreak: { [monitor] in
                monitor.endBreak()
            }
        )
        tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        monitor.tick(
            tasks: tasks,
            at: .now,
            in: context,
            excludingFromPause: meetings.protectedTaskID
        )
        publishTotal(at: .now)
    }

    private func publishTotal(at date: Date) {
        guard let context else { return }
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        publishTotal(tasks: tasks, at: date)
    }

    private func publishTotal(tasks: [TaskItem], at date: Date) {
        onTotalElapsed?(TimeTracker.totalElapsed(tasks, at: date))
    }
}
