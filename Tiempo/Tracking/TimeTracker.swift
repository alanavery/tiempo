import Foundation
import SwiftData

@MainActor
enum TimeTracker {
    static func start(_ task: TaskItem, at now: Date = .now, in context: ModelContext) throws {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.runningSince != nil }
        )
        let running = try context.fetch(descriptor)
        for other in running where other.persistentModelID != task.persistentModelID {
            pause(other, at: now)
        }
        if task.runningSince == nil {
            task.runningSince = now
        }
    }

    static func pause(_ task: TaskItem, at now: Date = .now) {
        guard let runningSince = task.runningSince else { return }
        task.accumulated += max(0, now.timeIntervalSince(runningSince))
        task.runningSince = nil
    }

    static func setElapsed(_ task: TaskItem, to interval: TimeInterval) {
        task.runningSince = nil
        task.accumulated = max(0, interval)
    }

    static func elapsed(_ task: TaskItem, at now: Date = .now) -> TimeInterval {
        let running = task.runningSince.map { max(0, now.timeIntervalSince($0)) } ?? 0
        return task.accumulated + running
    }

    static func totalElapsed(_ tasks: [TaskItem], at now: Date = .now) -> TimeInterval {
        tasks.reduce(0) { $0 + elapsed($1, at: now).rounded(.down) }
    }

    static func resetAll(in context: ModelContext) throws {
        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        for task in tasks {
            task.accumulated = 0
            task.runningSince = nil
        }
    }

    static let quarterHour: TimeInterval = 15 * 60

    static func balanceWorkday(
        tasks: [TaskItem],
        breakTotal: TimeInterval,
        workday: TimeInterval,
        at now: Date = .now
    ) {
        for task in tasks where task.runningSince != nil {
            pause(task, at: now)
        }
        balanceBreakTime(tasks: tasks, breakTotal: breakTotal, at: now)
        roundUpToQuarterHour(tasks: tasks)
        trimToWorkday(tasks: tasks, workday: workday)
    }

    static func balanceBreakTime(tasks: [TaskItem], breakTotal: TimeInterval, at now: Date = .now) {
        guard breakTotal > 0 else { return }
        let eligible = tasks.filter { elapsed($0, at: now) >= 60 }
        let weightSum = eligible.reduce(0) { $0 + elapsed($1, at: now) }
        guard weightSum > 0 else { return }
        for task in eligible {
            let share = elapsed(task, at: now) / weightSum
            if task.runningSince != nil {
                pause(task, at: now)
            }
            task.accumulated += breakTotal * share
        }
    }

    static func roundUpToQuarterHour(tasks: [TaskItem]) {
        for task in tasks {
            task.runningSince = nil
            task.accumulated = roundedUpToQuarterHour(task.accumulated)
        }
    }

    static func trimToWorkday(tasks: [TaskItem], workday: TimeInterval) {
        let limit = max(0, workday)
        while tasks.reduce(0, { $0 + $1.accumulated }) > limit {
            guard let longest = tasks.max(by: { $0.accumulated < $1.accumulated }),
                  longest.accumulated >= quarterHour
            else { return }
            longest.accumulated -= quarterHour
        }
    }

    static func roundedUpToQuarterHour(_ interval: TimeInterval) -> TimeInterval {
        let seconds = max(0, interval)
        guard seconds > 0 else { return 0 }
        return (seconds / quarterHour).rounded(.up) * quarterHour
    }
}
