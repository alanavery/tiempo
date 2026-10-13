import Foundation
import SwiftData
import UserNotifications

@MainActor
@Observable
final class BreakMonitor {
    var workdayHours: Double {
        didSet { storeSettings(changed: true) }
    }

    var intervals: Int {
        didSet { storeSettings(changed: true) }
    }

    var breakMinutes: Double {
        didSet { storeSettings(changed: true) }
    }

    private(set) var cycle = BreakCycle()
    private var settingsNeedSnap = false
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Keys.workdayHours) == nil {
            workdayHours = 8
            intervals = 5
            breakMinutes = 15
        } else {
            workdayHours = defaults.double(forKey: Keys.workdayHours)
            intervals = defaults.integer(forKey: Keys.intervals)
            breakMinutes = defaults.double(forKey: Keys.breakMinutes)
        }
        cycle = BreakCycle(
            breaksCompleted: defaults.integer(forKey: Keys.completed),
            onBreak: defaults.bool(forKey: Keys.onBreak)
        )
        settingsNeedSnap = false
    }

    var segmentLength: TimeInterval? {
        BreakSchedule.segmentLength(
            workdayHours: workdayHours,
            intervals: intervals,
            breakMinutes: breakMinutes
        )
    }

    func tick(tasks: [TaskItem], at date: Date = .now, in context: ModelContext) {
        let total = TimeTracker.totalElapsed(tasks, at: date)
        guard let segment = segmentLength else { return }

        if settingsNeedSnap {
            settingsNeedSnap = false
            cycle = BreakSchedule.phase(total: total, segment: segment, intervals: intervals) ?? BreakCycle()
            storeCycle()
            return
        }

        let (next, signals) = BreakSchedule.advance(
            total: total,
            segment: segment,
            intervals: intervals,
            cycle: cycle
        )
        guard next != cycle else { return }
        cycle = next
        storeCycle()
        if signals.contains(.notify) {
            postBreakNotification()
        }
        if signals.contains(.pause) {
            pauseRunningTasks(at: date, in: context)
        }
    }

    func endBreak() {
        guard cycle.onBreak else { return }
        cycle = BreakCycle(breaksCompleted: cycle.breaksCompleted + 1, onBreak: false)
        storeCycle()
    }

    func resetCycle() {
        settingsNeedSnap = false
        cycle = BreakCycle()
        storeCycle()
    }

    private func pauseRunningTasks(at date: Date, in context: ModelContext) {
        context.rollback()
        let running = (try? context.fetch(
            FetchDescriptor<TaskItem>(predicate: #Predicate { $0.runningSince != nil })
        )) ?? []
        guard !running.isEmpty else { return }
        for task in running {
            TimeTracker.pause(task, at: date)
        }
        try? context.save()
    }

    private func storeSettings(changed: Bool) {
        defaults.set(workdayHours, forKey: Keys.workdayHours)
        defaults.set(intervals, forKey: Keys.intervals)
        defaults.set(breakMinutes, forKey: Keys.breakMinutes)
        if changed {
            settingsNeedSnap = true
            if segmentLength != nil {
                requestNotificationPermission()
            }
        }
    }

    private func storeCycle() {
        defaults.set(cycle.breaksCompleted, forKey: Keys.completed)
        defaults.set(cycle.onBreak, forKey: Keys.onBreak)
    }

    private func requestNotificationPermission() {
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        }
    }

    private func postBreakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time for a break"
        let minutes = max(0, Int(breakMinutes.rounded(.down)))
        if minutes > 0 {
            content.body = "Timers paused. Take a \(minutes)-minute break, then start a timer for the next interval."
        } else {
            content.body = "Timers paused. Start a timer when you are ready for the next interval."
        }
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        Task {
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    private enum Keys {
        static let workdayHours = "break.workdayHours"
        static let intervals = "break.intervals"
        static let breakMinutes = "break.breakMinutes"
        static let completed = "break.completed"
        static let onBreak = "break.onBreak"
    }
}
