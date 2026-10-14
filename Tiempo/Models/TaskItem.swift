import Foundation
import SwiftData

@Model
final class TaskItem {
    var name: String
    var createdAt: Date
    var accumulated: TimeInterval
    var runningSince: Date?
    var sortIndex: Int
    var project: Project?

    init(name: String, project: Project, createdAt: Date = .now, sortIndex: Int = 0) {
        self.name = name
        self.createdAt = createdAt
        self.accumulated = 0
        self.runningSince = nil
        self.sortIndex = sortIndex
        self.project = project
    }

    var isRunning: Bool {
        runningSince != nil
    }
}
