import Foundation
import SwiftData
import UserNotifications

@MainActor
@Observable
final class BreakMonitor {
    var interval: TimeInterval {
        didSet { storeSettings(changed: true) }
    }

    var breakDuration: TimeInterval {
        didSet { storeSettings(changed: true) }
    }

    private(set) var cycle = BreakCycle()
    private var settingsNeedSnap = false
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        interval = defaults.double(forKey: Keys.interval)
        breakDuration = defaults.double(forKey: Keys.breakDuration)
        cycle = BreakCycle(
            breaksCompleted: defaults.integer(forKey: Keys.completed),
            onBreak: defaults.bool(forKey: Keys.onBreak)
        )
    }

    func tick(tasks: [TaskItem], at date: Date = .now, in context: ModelContext) {
        let total = TimeTracker.totalElapsed(tasks, at: date)
        if settingsNeedSnap {
            settingsNeedSnap = false
            let next = BreakSchedule.phase(total: total, interval: interval, breakDuration: breakDuration) ?? BreakCycle()
            let enteredBreak = next.onBreak && !cycle.onBreak
            cycle = next
            storeCycle()
            if enteredBreak {
                postBreakNotification()
            }
            return
        }

        let (next, signals) = BreakSchedule.advance(
            total: total,
            interval: interval,
            breakDuration: breakDuration,
            cycle: cycle
        )
        guard next != cycle else { return }
        cycle = next
        storeCycle()
        if signals.contains(.notify) {
            postBreakNotification()
        }
        if signals.contains(.pause) {
            let running = tasks.filter { $0.modelContext != nil && !$0.isDeleted && $0.isRunning }
            guard !running.isEmpty else { return }
            for task in running {
                TimeTracker.pause(task, at: date)
            }
            try? context.save()
        }
    }

    func resetCycle() {
        settingsNeedSnap = false
        cycle = BreakCycle()
        storeCycle()
    }

    private func storeSettings(changed: Bool) {
        defaults.set(interval, forKey: Keys.interval)
        defaults.set(breakDuration, forKey: Keys.breakDuration)
        if changed {
            settingsNeedSnap = true
            if interval > 0 {
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
        if breakDuration > 0 {
            content.body = "Your timer will keep running for \(DurationFormat.string(from: breakDuration)), then pause."
        } else {
            content.body = "Your timer will pause now."
        }
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        Task {
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    private enum Keys {
        static let interval = "break.interval"
        static let breakDuration = "break.duration"
        static let completed = "break.completed"
        static let onBreak = "break.onBreak"
    }
}
