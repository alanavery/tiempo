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
}
