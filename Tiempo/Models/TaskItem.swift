import Foundation
import SwiftData

@Model
final class TaskItem {
    var name: String
    var createdAt: Date
    var accumulated: TimeInterval
    var runningSince: Date?
    var project: Project?

    init(name: String, project: Project, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
        self.accumulated = 0
        self.runningSince = nil
        self.project = project
    }

    var isRunning: Bool {
        runningSince != nil
    }
}
